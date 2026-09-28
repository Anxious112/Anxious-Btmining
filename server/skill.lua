-- Mining skill lives directly on each rig (Rigs[id].xp / .level, loaded and
-- persisted as part of the normal rig row by server/main.lua and
-- server/rig_state.lua's existing dirty-flag flush) -- there's no separate
-- cache or table here, just the level-curve math and the callbacks that read
-- it. See config.lua's Config.Skill for why this is per-rig, not per-player.

-- Cumulative XP required to REACH each level, precomputed once so lookups
-- don't repeat float-power math. Thresholds[1] = 0 (starting level).
local Thresholds = { [1] = 0 }
do
    local cumulative = 0
    for level = 2, Config.Skill.maxLevel do
        cumulative += math.floor(Config.Skill.baseXp * (level ^ Config.Skill.growth))
        Thresholds[level] = cumulative
    end
end

local function levelForXp(xp)
    local level = 1
    for l = 2, Config.Skill.maxLevel do
        if xp >= Thresholds[l] then
            level = l
        else
            break
        end
    end
    return level
end

---@param level integer
---@return integer cumulativeXpForNextLevel -- 0 if already at maxLevel
local function xpForNextLevel(level)
    if level >= Config.Skill.maxLevel then return 0 end
    return Thresholds[level + 1]
end

---@param rigId integer
---@param amount integer
---@return integer oldLevel, integer newLevel
function AddRigXp(rigId, amount)
    local rig = GetRig(rigId)
    if not rig then return 1, 1 end

    local oldLevel = rig.level
    rig.xp += amount
    rig.level = levelForXp(rig.xp)
    MarkDirty(rigId)

    return oldLevel, rig.level
end

local function hasAccess(source, rig)
    if not rig then return false end
    return HasRigAccess(rig, GetCitizenId(source))
end

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:getSkillProgress', function(source, rigId)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return nil end

    return {
        level = rig.level,
        xp = rig.xp,
        maxLevel = Config.Skill.maxLevel,
        currentLevelXp = Thresholds[rig.level],
        nextLevelXp = xpForNextLevel(rig.level), -- 0 means already max level
    }
end)

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:getGpuShop', function(source, rigId)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return {} end

    local out = {}
    for key, tier in pairs(Config.GpuTiers) do
        out[#out + 1] = {
            key = key,
            label = tier.label,
            price = tier.price,
            requiredLevel = tier.requiredLevel,
            hashrate = tier.hashrate,
            powerDraw = tier.powerDraw,
            heatPerSecond = tier.heatPerSecond,
            unlocked = rig.level >= tier.requiredLevel,
        }
    end

    -- `pairs()` order is unspecified -- with 20 tiers now, an unsorted shop
    -- list would read as random noise. Sort weakest-to-strongest so it reads
    -- as a real progression ladder.
    table.sort(out, function(a, b)
        if a.requiredLevel ~= b.requiredLevel then return a.requiredLevel < b.requiredLevel end
        return a.price < b.price
    end)

    return out
end)

---@param source number
---@param rigId integer
---@param tierKey string
lib.callback.register('anxious_btcmining:server:buyGpu', function(source, rigId, tierKey)
    local tier = Config.GpuTiers[tierKey]
    if not tier then return false end

    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return false end

    if rig.level < tier.requiredLevel then
        return false, ('This rig needs to be level %d first'):format(tier.requiredLevel)
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.money[Config.Currency] < tier.price then
        return false, 'Not enough money'
    end

    local added = exports.ox_inventory:AddItem(source, tier.item, 1, { durability = tier.maxCondition })
    if not added then return false, 'Your inventory is full' end

    player.Functions.RemoveMoney(Config.Currency, tier.price, 'btcmining-gpu-purchase')

    return true
end)
