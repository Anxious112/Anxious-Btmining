-- Lets a rig's owner share dashboard access (install/remove GPUs, collect,
-- toggle power, buy GPUs -- everything except managing access itself) with
-- other players, without handing over the rig's citizenid-based ownership.
-- HasRigAccess (server/rig_state.lua) is what every other callback checks;
-- this file only owns the grant/revoke/lookup flow.

local MAX_SHARED = 8 -- generous but bounded, so a rig's access list can't grow unbounded

---@param citizenid string
---@return string? name -- nil if no character exists for this citizenid
local function resolveName(citizenid)
    local player = GetPlayerByCitizenId(citizenid) or exports.qbx_core:GetOfflinePlayer(citizenid)
    if not player then return nil end

    local charinfo = player.PlayerData.charinfo
    return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
end

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:getRigAccess', function(source, rigId)
    local rig = GetRig(rigId)
    if not rig then return {} end

    local citizenid = GetCitizenId(source)
    if not citizenid or rig.citizenid ~= citizenid then return {} end

    local out = {}
    for _, granted in ipairs(rig.shared_access) do
        out[#out + 1] = { citizenid = granted, name = resolveName(granted) or 'Unknown' }
    end
    return out
end)

-- Online players within a short radius of the requester, for the "add
-- nearby player" picker -- excludes the requester and anyone already listed
-- on this rig.
---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:getNearbyPlayers', function(source, rigId)
    local rig = GetRig(rigId)
    if not rig then return {} end

    local myCitizenid = GetCitizenId(source)
    local myCoords = GetEntityCoords(GetPlayerPed(source))

    local excluded = { [rig.citizenid] = true }
    for _, granted in ipairs(rig.shared_access) do
        excluded[granted] = true
    end

    local out = {}
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and target ~= source then
            local targetCitizenid = GetCitizenId(target)
            if targetCitizenid and not excluded[targetCitizenid] then
                local dist = #(myCoords - GetEntityCoords(GetPlayerPed(target)))
                if dist <= 10.0 then
                    out[#out + 1] = { citizenid = targetCitizenid, name = resolveName(targetCitizenid) or ('Player %s'):format(playerId) }
                end
            end
        end
    end

    return out
end)

---@param source number
---@param rigId integer
---@param targetCitizenid string
lib.callback.register('anxious_btcmining:server:grantAccess', function(source, rigId, targetCitizenid)
    local rig = GetRig(rigId)
    if not rig then return false end

    local citizenid = GetCitizenId(source)
    if not citizenid or rig.citizenid ~= citizenid then return false, 'Only the owner can manage access' end

    if type(targetCitizenid) ~= 'string' or targetCitizenid == '' then return false end
    if targetCitizenid == rig.citizenid then return false, 'You already own this rig' end

    for _, granted in ipairs(rig.shared_access) do
        if granted == targetCitizenid then return false, 'That player already has access' end
    end

    if #rig.shared_access >= MAX_SHARED then
        return false, ('You can only share this rig with %d people'):format(MAX_SHARED)
    end

    if not resolveName(targetCitizenid) then
        return false, 'No character found for that citizen ID'
    end

    rig.shared_access[#rig.shared_access + 1] = targetCitizenid
    MarkDirty(rigId)

    local targetPlayer = GetPlayerByCitizenId(targetCitizenid)
    if targetPlayer then
        exports.qbx_core:Notify(targetPlayer.PlayerData.source, 'You were given access to a mining rig', 'success')
    end

    return true
end)

---@param source number
---@param rigId integer
---@param targetCitizenid string
lib.callback.register('anxious_btcmining:server:revokeAccess', function(source, rigId, targetCitizenid)
    local rig = GetRig(rigId)
    if not rig then return false end

    local citizenid = GetCitizenId(source)
    if not citizenid or rig.citizenid ~= citizenid then return false, 'Only the owner can manage access' end

    for i, granted in ipairs(rig.shared_access) do
        if granted == targetCitizenid then
            table.remove(rig.shared_access, i)
            MarkDirty(rigId)
            return true
        end
    end

    return false
end)
