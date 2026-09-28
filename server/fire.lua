-- Lets a nearby player fight a burning rig early via the custom "Coolant
-- Purge" minigame (client/fire.lua + client/minigame.lua) instead of just
-- waiting for it to cool out on its own (server/rig_state.lua still does
-- that passively regardless). Same request/resolve/cooldown shape as
-- server/theft.lua's hack flow, for the same reason: the client is trusted
-- to report whether it won the minigame, same trust level this resource
-- already extends to the hack flow.

local Cooldowns = {} ---@type table<integer, integer> -- rigId -> os.time() the cooldown ends
local InProgress = {} ---@type table<integer, number> -- rigId -> source currently attempting it

---@param heat number 0-100
---@return table -- SweepDifficulty for web/src/components/minigames/SweepGame.tsx
local function difficultyForHeat(heat)
    -- Hotter rig = smaller, faster-moving target window. t is 0 right at
    -- meltdownPct and 1 at heat=100, so the roll gets meaner the longer the
    -- fire's been left to cook.
    local span = math.max(1, 100 - Config.Heat.meltdownPct)
    local t = math.max(0, math.min(1, (heat - Config.Heat.meltdownPct) / span))

    return {
        variant = 'linear',
        zoneWidthPct = 18 - (t * 10),          -- 18% down to 8%
        speedMs = math.floor(750 - (t * 330)), -- 750ms down to 420ms per sweep
        requiredHits = 4,
        maxMisses = 1,
        timeLimitMs = 11000,
    }
end

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:requestExtinguish', function(source, rigId)
    local rig = GetRig(rigId)
    if not rig or not rig.status.onFire then return false, 'This rig isn\'t on fire' end
    if rig.status.seized then return false end

    if InProgress[rigId] then
        return false, 'Someone is already fighting this fire'
    end

    if Cooldowns[rigId] and Cooldowns[rigId] > os.time() then
        return false, 'The fire is too fierce to approach yet'
    end

    local held = exports.ox_inventory:Search(source, 'count', Config.Heat.extinguisherItem)
    if not held or held < 1 then
        return false, 'You need a fire extinguisher'
    end

    InProgress[rigId] = source
    return true, difficultyForHeat(rig.heat)
end)

---@param source number
---@param rigId integer
---@param success boolean
lib.callback.register('anxious_btcmining:server:resolveExtinguish', function(source, rigId, success)
    if InProgress[rigId] ~= source then return false end
    InProgress[rigId] = nil

    local rig = GetRig(rigId)
    if not rig then return false end

    if success then
        rig.status.onFire = false
        -- Knock heat down below the warm threshold rather than to zero --
        -- putting the fire out isn't the same as the rig being fully cooled.
        rig.heat = math.min(rig.heat, math.max(0, Config.Heat.warmPct - 5))
        MarkDirty(rigId)
        BroadcastRigSummaries(-1)
        return true
    end

    Cooldowns[rigId] = os.time() + math.floor(Config.Heat.extinguishCooldownMs / 1000)
    return false
end)
