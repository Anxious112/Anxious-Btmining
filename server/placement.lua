---@param source number
---@param data { rigModel: string, coords: { x: number, y: number, z: number }, heading: number, slot: number }
lib.callback.register('anxious_btcmining:server:confirmPlacement', function(source, data)
    local model = Config.RigModels[data.rigModel]
    if not model then return false end

    local citizenid = GetCitizenId(source)
    if not citizenid then return false end

    local coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    if not Config.Placement.requireInsideZone(coords) then
        return false, 'You can\'t place a rig here'
    end

    local held = exports.ox_inventory:Search(source, 'count', model.item)
    if not held or held < 1 then
        return false, 'You don\'t have that item anymore'
    end

    local removed = exports.ox_inventory:RemoveItem(source, model.item, 1)
    if not removed then
        return false, 'Failed to consume the item'
    end

    local id = CreateRig(citizenid, data.rigModel, coords, data.heading)
    if not id then
        -- Refund on failure -- shouldn't happen, but never eat a player's item silently.
        exports.ox_inventory:AddItem(source, model.item, 1)
        return false, 'Failed to place the rig'
    end

    BroadcastRigSummaries(-1)

    return true, id
end)
