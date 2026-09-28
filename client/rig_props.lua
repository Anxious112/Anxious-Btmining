local ActiveFires = {} ---@type table<integer, integer> -- rigId -> fire handle, this client only

-- `StartScriptFire`/`RemoveScriptFire` aren't network-synced -- each nearby
-- client starts/stops its own local fire, same as how this file already
-- streams the rig prop itself in/out per-client by distance. The native
-- also handles nearby-ped burn damage for free, so no custom damage loop
-- is needed here.
local function setFireActive(id, coords, active)
    local burning = ActiveFires[id]

    if active and not burning then
        ActiveFires[id] = StartScriptFire(coords.x, coords.y, coords.z + 0.3, 15, false)
    elseif not active and burning then
        RemoveScriptFire(burning)
        ActiveFires[id] = nil
    end
end

local function despawnProp(id)
    local entry = RigProps[id]
    if not entry then return end

    if entry.entity and DoesEntityExist(entry.entity) then
        exports.ox_target:removeLocalEntity(entry.entity)
        DeleteEntity(entry.entity)
    end

    setFireActive(id, nil, false)
    RigProps[id] = nil
end

local function spawnProp(rig)
    local model = Config.RigModels[rig.rig_model]
    if not model then return end

    despawnProp(rig.id)

    lib.requestModel(model.model, 10000)

    local obj = CreateObjectNoOffset(model.model, rig.coords.x, rig.coords.y, rig.coords.z, false, false, false)
    SetEntityHeading(obj, rig.heading or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(model.model)

    RigProps[rig.id] = { entity = obj, data = rig }
    AttachRigTarget(obj, rig)
    setFireActive(rig.id, rig.coords, rig.status and rig.status.onFire or false)
end

CreateThread(function()
    while true do
        Wait(2000)

        local pedCoords = GetEntityCoords(cache.ped)

        for id, rig in pairs(RigCache) do
            local dist = #(pedCoords - rig.coords)
            local existing = RigProps[id]

            if dist <= Config.Placement.spawnRadius then
                if not existing or not DoesEntityExist(existing.entity) then
                    spawnProp(rig)
                elseif (existing.data.status and existing.data.status.onFire or false) ~= (rig.status and rig.status.onFire or false) then
                    -- Fire status changed since this prop was spawned (or last
                    -- refreshed here) -- resync the target menu and the local
                    -- fire effect without a full respawn.
                    existing.data = rig
                    exports.ox_target:removeLocalEntity(existing.entity)
                    AttachRigTarget(existing.entity, rig)
                    setFireActive(id, rig.coords, rig.status and rig.status.onFire or false)
                end
            elseif dist >= Config.Placement.despawnRadius and existing then
                despawnProp(id)
            end
        end

        -- Clean up props for rigs that no longer exist server-side (picked
        -- up, seized, deleted).
        for id in pairs(RigProps) do
            if not RigCache[id] then
                despawnProp(id)
            end
        end
    end
end)

RegisterNetEvent('anxious_btcmining:client:removeRig', function(id)
    despawnProp(id)
end)
