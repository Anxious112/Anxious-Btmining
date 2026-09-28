local placing = false
local ghost = nil

local function stopPlacement()
    placing = false
    if ghost and DoesEntityExist(ghost) then
        DeleteEntity(ghost)
    end
    ghost = nil
end

local function raycastFromCamera(maxDist)
    local camCoord = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local rad = vector3(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
    local num = math.abs(math.cos(rad.x))
    local dir = vector3(-math.sin(rad.z) * num, math.cos(rad.z) * num, math.sin(rad.x))
    local dest = camCoord + (dir * maxDist)

    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, 511, cache.ped, 7
    )
    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit == 1 then return endCoords end
    return dest
end

---@param rigModel string -- key into Config.RigModels
local function startPlacement(rigModel)
    local model = Config.RigModels[rigModel]
    if not model then return end
    if placing then stopPlacement() end

    lib.requestModel(model.model, 10000)

    placing = true
    local heading = GetEntityHeading(cache.ped)
    local pedCoords = GetEntityCoords(cache.ped)

    ghost = CreateObjectNoOffset(model.model, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetModelAsNoLongerNeeded(model.model)

    local lastPos = pedCoords

    CreateThread(function()
        while placing do
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 140, true)

            local endCoords = raycastFromCamera(Config.Placement.maxDistance)
            if endCoords and ghost and DoesEntityExist(ghost) then
                SetEntityCoordsNoOffset(ghost, endCoords.x, endCoords.y, endCoords.z, false, false, false)
                SetEntityHeading(ghost, heading)
                lastPos = endCoords
                lib.showTextUI('[E] Place   [BACKSPACE] Cancel   [Scroll] Rotate')
            end

            if IsControlJustPressed(0, 14) then
                heading = (heading + Config.Placement.rotateStep) % 360.0
            elseif IsControlJustPressed(0, 15) then
                heading = (heading - Config.Placement.rotateStep) % 360.0
            end

            if IsControlJustPressed(0, 38) then
                local ok, result = lib.callback.await('anxious_btcmining:server:confirmPlacement', false, {
                    rigModel = rigModel,
                    coords = { x = lastPos.x, y = lastPos.y, z = lastPos.z },
                    heading = heading,
                })

                if not ok and result then
                    lib.notify({ type = 'error', description = result })
                end

                lib.hideTextUI()
                stopPlacement()
            elseif IsControlJustPressed(0, 177) then -- backspace
                lib.hideTextUI()
                stopPlacement()
            end
        end
    end)
end

exports('usePlaceable', function(data)
    local itemName = data?.name
    if not itemName then return end

    for key, model in pairs(Config.RigModels) do
        if model.item == itemName then
            return startPlacement(key)
        end
    end

    for key, generator in pairs(Config.Generator) do
        if generator.item == itemName then
            -- Generators reuse the same ghost-placement flow but aren't rigs
            -- themselves -- left as a hook for buyers who want a physical
            -- generator prop; out of the box a generator is just an
            -- inventory item consumed toward Config.PowerMode = 'generator'
            -- capacity, no world prop required. Wire a startPlacement
            -- variant here if you want generators to be placeable objects.
            return
        end
    end
end)
