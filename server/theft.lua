local Cooldowns = {} ---@type table<integer, integer> -- rigId -> os.time() the cooldown ends
local InProgress = {} ---@type table<integer, number> -- rigId -> source currently attempting it
local AttemptsToday = {} ---@type table<integer, integer>

-- Resets the daily attempt cap once every 24h -- simple in-memory counter,
-- not tied to real calendar days, which is fine for an anti-farming backstop.
CreateThread(function()
    while true do
        Wait(86400000)
        AttemptsToday = {}
    end
end)

local function getSecurityLevel(rig)
    -- Config.SecurityUpgrades maps an ox_inventory item to a level -- left
    -- empty by default (see config.lua), so every rig is level 1 unless a
    -- buyer wires up their own upgrade item check here.
    return 1
end

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:requestHack', function(source, rigId)
    if not Config.Theft.enabled then return false end

    local rig = GetRig(rigId)
    if not rig then return false end

    local citizenid = GetCitizenId(source)
    if HasRigAccess(rig, citizenid) then
        return false, 'You already have access to this rig'
    end

    if rig.status.seized or rig.status.onFire then
        return false, 'This rig isn\'t accessible right now'
    end

    if InProgress[rigId] then
        return false, 'Someone is already attempting this'
    end

    if Cooldowns[rigId] and Cooldowns[rigId] > os.time() then
        return false, 'This rig was hit recently, try again later'
    end

    if Config.Theft.maxAttemptsPerDay > 0 then
        local attempts = AttemptsToday[rigId] or 0
        if attempts >= Config.Theft.maxAttemptsPerDay then
            return false, 'This rig has hit its daily attempt limit'
        end
    end

    InProgress[rigId] = source
    AttemptsToday[rigId] = (AttemptsToday[rigId] or 0) + 1

    local level = math.min(getSecurityLevel(rig), #Config.Theft.difficulty)
    return true, Config.Theft.difficulty[level]
end)

---@param source number
---@param rigId integer
---@param success boolean
lib.callback.register('anxious_btcmining:server:resolveHack', function(source, rigId, success)
    local rig = GetRig(rigId)

    -- Always clear the lock, even if the rig vanished mid-attempt.
    if InProgress[rigId] ~= source then
        return false
    end
    InProgress[rigId] = nil

    if not rig then return false end

    if success then
        local fraction = Config.Theft.stealFraction.min +
            math.random() * (Config.Theft.stealFraction.max - Config.Theft.stealFraction.min)
        local stolenMicro = math.floor(rig.banked_micro_btc * fraction)

        if stolenMicro > 0 then
            rig.banked_micro_btc -= stolenMicro
            MarkDirty(rigId)

            local wholeItems = math.floor(stolenMicro / Config.MicroBtcPerItem)
            if wholeItems > 0 then
                exports.ox_inventory:AddItem(source, Config.BtcItemName, wholeItems)
            end
        end

        Cooldowns[rigId] = os.time() + math.floor(Config.Theft.cooldownMs / 1000)

        if Config.Theft.alertOwner then
            local owner = exports.qbx_core:GetPlayerByCitizenId(rig.citizenid)
            if owner then
                exports.qbx_core:Notify(owner.PlayerData.source, 'Your mining rig was just hacked', 'error')
            end
        end

        return true
    end

    Cooldowns[rigId] = os.time() + math.floor(Config.Theft.failCooldownMs / 1000)

    if Config.Theft.alertPoliceOnFail then
        -- Intentionally left as a generic hook rather than a dispatch call --
        -- wire this to your own dispatch resource, it varies too much
        -- between servers to bake in one implementation here.
        TriggerEvent('anxious_btcmining:hackFailedNearby', rig.coords)
    end

    return false
end)

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:stealGpu', function(source, rigId)
    if not Config.Theft.allowGpuTheft then return false end

    local rig = GetRig(rigId)
    if not rig then return false end

    local citizenid = GetCitizenId(source)
    if HasRigAccess(rig, citizenid) then return false end

    local occupiedIndexes = {}
    for i, slot in ipairs(rig.slots) do
        if slot and slot.tier then occupiedIndexes[#occupiedIndexes + 1] = i end
    end
    if #occupiedIndexes == 0 then return false end

    local index = occupiedIndexes[math.random(#occupiedIndexes)]
    local slot = rig.slots[index]
    local tier = GetGpuTier(slot.tier)
    if not tier then return false end

    local loss = math.random(Config.Theft.gpuTheftConditionLoss.min, Config.Theft.gpuTheftConditionLoss.max)
    local durability = math.max(1, slot.durability - loss)

    rig.slots[index] = false
    MarkDirty(rigId)

    exports.ox_inventory:AddItem(source, tier.item, 1, { durability = durability })

    return true
end)
