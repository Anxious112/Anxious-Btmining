-- Shared, cross-file globals (no `local`) -- every other server file in this
-- resource reads/writes these directly, same single-resource convention used
-- throughout this codebase rather than a module/require system.

---@class MiningRig
---@field id integer
---@field citizenid string
---@field rig_model string
---@field coords vector3
---@field heading number
---@field slots table[] -- fixed-length array of { tier: string|false, durability: number }
---@field heat number -- 0-100
---@field power_state boolean
---@field banked_micro_btc integer
---@field uptime_seconds integer
---@field last_tick integer -- os.time()
---@field status table -- { damaged: boolean, onFire: boolean, seized: boolean }
---@field shared_access string[] -- citizenids granted the same dashboard access as the owner

Rigs = {} ---@type table<integer, MiningRig>

---@param rig MiningRig
---@param citizenid string?
---@return boolean
function HasRigAccess(rig, citizenid)
    if not citizenid then return false end
    if rig.citizenid == citizenid then return true end

    for _, granted in ipairs(rig.shared_access) do
        if granted == citizenid then return true end
    end

    return false
end
local Dirty = {} ---@type table<integer, true>

function MarkDirty(id)
    Dirty[id] = true
end

---@param id integer
---@return MiningRig?
function GetRig(id)
    return Rigs[id]
end

---@param citizenid string
---@return MiningRig[]
function GetPlayerRigs(citizenid)
    local out = {}
    for _, rig in pairs(Rigs) do
        if rig.citizenid == citizenid then
            out[#out + 1] = rig
        end
    end
    return out
end

local function encodeRig(rig)
    return {
        coords = json.encode({ x = rig.coords.x, y = rig.coords.y, z = rig.coords.z }),
        slots = json.encode(rig.slots),
        status = json.encode(rig.status),
        shared_access = json.encode(rig.shared_access),
    }
end

-- Batched persistence -- rigs only get written to the DB when something about
-- them actually changed (a tick advanced their state, a GPU was installed,
-- etc), not on some blind interval. Same shape as the dirty-flag pattern
-- plt-illegal-jobs' placeable-lab tick loop uses.
function FlushDirty()
    local ids = {}
    for id in pairs(Dirty) do
        ids[#ids + 1] = id
    end
    Dirty = {}

    for _, id in ipairs(ids) do
        local rig = Rigs[id]
        if rig then
            local encoded = encodeRig(rig)
            MySQL.Async.execute([[
                UPDATE `mining_rigs` SET
                    `heading` = ?, `heat` = ?, `power_state` = ?, `banked_micro_btc` = ?,
                    `uptime_seconds` = ?, `last_tick` = ?, `coords` = ?, `slots` = ?, `status` = ?,
                    `xp` = ?, `level` = ?, `shared_access` = ?
                WHERE `id` = ?
            ]], {
                rig.heading, rig.heat, rig.power_state and 1 or 0, rig.banked_micro_btc,
                rig.uptime_seconds, rig.last_tick, encoded.coords, encoded.slots, encoded.status,
                rig.xp, rig.level, encoded.shared_access,
                id,
            })
        end
    end
end

---@param tierKey string
---@return table?
function GetGpuTier(tierKey)
    return tierKey and Config.GpuTiers[tierKey] or nil
end

local function occupiedSlots(rig)
    local out = {}
    for i, slot in ipairs(rig.slots) do
        if slot and slot.tier then
            out[#out + 1] = { index = i, slot = slot, def = GetGpuTier(slot.tier) }
        end
    end
    return out
end

local function totalPowerDraw(rig)
    local watts = 0
    for _, entry in ipairs(occupiedSlots(rig)) do
        if entry.def then
            watts += entry.def.powerDraw
        end
    end
    return watts
end

-- 1.0 at/under Config.Heat.warmPct, ramps linearly to 0.0 at meltdownPct.
local function heatEfficiency(heat)
    local warm, meltdown = Config.Heat.warmPct, Config.Heat.meltdownPct
    if heat <= warm then return 1.0 end
    if heat >= meltdown then return 0.0 end
    return 1.0 - ((heat - warm) / (meltdown - warm))
end

-- Damages (or destroys) a random installed GPU. Returns true if a GPU was
-- destroyed outright, so callers can decide whether to notify the owner.
local function damageRandomGpu(rig, amount)
    local occupied = occupiedSlots(rig)
    if #occupied == 0 then return false end

    local pick = occupied[math.random(#occupied)]
    pick.slot.durability -= amount

    if pick.slot.durability <= 0 then
        rig.slots[pick.index] = false
        return true
    end

    return false
end

-- Returns true if this tick flipped `status.onFire` either way, so the tick
-- loop knows to push a fresh summary to nearby clients -- without this,
-- RigCache (and the fire ptfx/target-menu warning it drives) only ever
-- reflects whatever the rig's status was when the player last loaded in.
local function advanceRig(rig, now)
    local elapsed = now - rig.last_tick
    if elapsed <= 0 then return false end

    local wasOnFire = rig.status.onFire

    -- Cap how much offline time counts, so a rig left mining during a long
    -- server outage can't accrue unlimited BTC.
    local cappedElapsed = math.min(elapsed, Config.MaxOfflineAccrualHours * 3600)

    local draw = totalPowerDraw(rig)
    local coolingCapacity = Config.Heat.baseCoolingCapacity
    local equilibrium = math.min(100, (draw / coolingCapacity) * Config.Heat.heatFactor)

    if rig.power_state then
        rig.heat = rig.heat + (equilibrium - rig.heat) * Config.Heat.changeRate
    else
        -- No new heat generated while shut down -- just cools toward zero.
        rig.heat = rig.heat + (0 - rig.heat) * Config.Heat.changeRate
    end
    rig.heat = math.max(0, math.min(100, rig.heat))

    if rig.power_state and rig.heat >= Config.Heat.criticalPct then
        if math.random() < Config.Heat.damageChancePerTick then
            local dmg = math.random(Config.Heat.damageAmount.min, Config.Heat.damageAmount.max)
            damageRandomGpu(rig, dmg)
        end
    end

    if rig.power_state and rig.heat >= Config.Heat.meltdownPct then
        if not rig.status.onFire and math.random() < Config.Heat.fireChancePerTick then
            rig.status.onFire = true
            rig.power_state = false
        end
    end

    if rig.status.onFire then
        if math.random() < Config.Heat.fireDestroyChance then
            damageRandomGpu(rig, 999)
        end
        -- Fire burns out once the rig has cooled back down (it's shut off,
        -- so heat is already trending toward zero every tick above).
        if rig.heat <= Config.Heat.warmPct then
            rig.status.onFire = false
        end
    end

    if rig.power_state then
        local hashrate = 0
        for _, entry in ipairs(occupiedSlots(rig)) do
            if entry.def then
                hashrate += entry.def.hashrate
            end
        end
        hashrate *= heatEfficiency(rig.heat)

        if hashrate > 0 then
            local hours = cappedElapsed / 3600
            rig.banked_micro_btc += math.floor(hashrate * hours * Config.Tick.microBtcPerHashPerHour)
            rig.uptime_seconds += cappedElapsed
        end
    end

    rig.last_tick = now
    MarkDirty(rig.id)

    return rig.status.onFire ~= wasOnFire
end

CreateThread(function()
    while true do
        Wait(Config.Tick.intervalMs)

        local now = os.time()
        local anyFireChanged = false
        for _, rig in pairs(Rigs) do
            if advanceRig(rig, now) then
                anyFireChanged = true
            end
        end

        FlushDirty()

        -- Only re-broadcast the lightweight world-prop summaries when a rig
        -- actually caught fire or burned out this tick -- everything else
        -- (heat, hashrate, balance) only matters to the owner's own dashboard,
        -- which already polls via getRigDetail while it's open.
        if anyFireChanged then
            BroadcastRigSummaries(-1)
        end
    end
end)
