Config = {}

-- =========================================================================
-- CORE / CURRENCY
-- =========================================================================

-- ox_inventory item name for the physical Bitcoin item. Must already exist
-- in your ox_inventory/data/items.lua (see docs/items/ox_inventory.txt for
-- the exact block to paste in if you don't have one yet). This is a whole,
-- integer-count item -- it cannot hold fractional amounts, which is why
-- accrued mining rewards are tracked separately per-rig (see
-- Config.MicroBtcPerItem below) rather than minted into inventory every tick.
Config.BtcItemName = 'bitcoin'

-- Cash currency used for power billing, GPU purchases (if sold via a shop
-- rather than a crafting recipe) and BTC sale payouts. 'bank' | 'cash' |
-- 'black_money' -- passed straight to player.Functions.AddMoney/RemoveMoney.
Config.Currency = 'bank'

-- How much of the internal accrual buffer equals one whole `bitcoin` item.
-- Raise this to make BTC feel rarer/slower to accumulate without touching
-- any of the hashrate numbers below. 1,000,000 = "micro-BTC", satoshi-style.
Config.MicroBtcPerItem = 1000000

-- =========================================================================
-- GPU TIERS
-- =========================================================================
-- Each tier must correspond to a non-stacking ox_inventory item (see
-- docs/items/ox_inventory.txt) so per-GPU durability can travel as item
-- metadata between inventory and an installed rig slot.
--
-- hashrate      arbitrary units/tick, only meaningful relative to other tiers
-- powerDraw     watts, drives Config.PowerMode cost/generator-capacity math
-- heatPerSecond how fast this GPU raises rig heat while active
-- price         cash cost via the dashboard's Buy GPU screen (server/callbacks.lua's buyGpu)
-- maxCondition  durability ceiling (0-100); GPUs are damaged by overheating
-- requiredLevel mining skill level needed before this tier is buyable -- see
--               Config.Skill below. Tiers at level 1 are available immediately.

-- 20 tiers on a single "ANX" GPU line, spaced across the full 1-25 level
-- range (see Config.Skill below) so there's almost always a new card to
-- chase. Stats compound roughly geometrically tier-to-tier (~12-25% per
-- step depending on the stat) rather than a flat curve, so the jump from
-- a tier01 to a tier20 rig feels dramatic rather than incremental.
Config.GpuTiers = {
    tier01 = { item = 'gpu_tier01', label = 'ANX-100',      hashrate = 8,   powerDraw = 90,  heatPerSecond = 0.60, price = 1800,  maxCondition = 100, requiredLevel = 1 },
    tier02 = { item = 'gpu_tier02', label = 'ANX-150',      hashrate = 10,  powerDraw = 100, heatPerSecond = 0.70, price = 2200,  maxCondition = 100, requiredLevel = 1 },
    tier03 = { item = 'gpu_tier03', label = 'ANX-200',      hashrate = 12,  powerDraw = 115, heatPerSecond = 0.80, price = 2700,  maxCondition = 100, requiredLevel = 2 },
    tier04 = { item = 'gpu_tier04', label = 'ANX-250',      hashrate = 14,  powerDraw = 130, heatPerSecond = 0.85, price = 3300,  maxCondition = 100, requiredLevel = 3 },
    tier05 = { item = 'gpu_tier05', label = 'ANX-300',      hashrate = 17,  powerDraw = 150, heatPerSecond = 0.95, price = 4000,  maxCondition = 100, requiredLevel = 4 },
    tier06 = { item = 'gpu_tier06', label = 'ANX-400',      hashrate = 20,  powerDraw = 170, heatPerSecond = 1.05, price = 5000,  maxCondition = 100, requiredLevel = 5 },
    tier07 = { item = 'gpu_tier07', label = 'ANX-500',      hashrate = 24,  powerDraw = 190, heatPerSecond = 1.20, price = 6100,  maxCondition = 100, requiredLevel = 6 },
    tier08 = { item = 'gpu_tier08', label = 'ANX-600',      hashrate = 29,  powerDraw = 215, heatPerSecond = 1.30, price = 7500,  maxCondition = 100, requiredLevel = 7 },
    tier09 = { item = 'gpu_tier09', label = 'ANX-700',      hashrate = 35,  powerDraw = 245, heatPerSecond = 1.45, price = 9100,  maxCondition = 100, requiredLevel = 8 },
    tier10 = { item = 'gpu_tier10', label = 'ANX-800',      hashrate = 41,  powerDraw = 275, heatPerSecond = 1.60, price = 11200, maxCondition = 100, requiredLevel = 9 },
    tier11 = { item = 'gpu_tier11', label = 'ANX-900',      hashrate = 50,  powerDraw = 310, heatPerSecond = 1.80, price = 13700, maxCondition = 100, requiredLevel = 10 },
    tier12 = { item = 'gpu_tier12', label = 'ANX-1000',     hashrate = 60,  powerDraw = 350, heatPerSecond = 2.00, price = 16800, maxCondition = 100, requiredLevel = 11 },
    tier13 = { item = 'gpu_tier13', label = 'ANX-1200',     hashrate = 72,  powerDraw = 400, heatPerSecond = 2.25, price = 20500, maxCondition = 100, requiredLevel = 13 },
    tier14 = { item = 'gpu_tier14', label = 'ANX-1400',     hashrate = 86,  powerDraw = 450, heatPerSecond = 2.50, price = 25200, maxCondition = 100, requiredLevel = 15 },
    tier15 = { item = 'gpu_tier15', label = 'ANX-1600',     hashrate = 103, powerDraw = 510, heatPerSecond = 2.80, price = 30800, maxCondition = 100, requiredLevel = 16 },
    tier16 = { item = 'gpu_tier16', label = 'ANX-1800',     hashrate = 124, powerDraw = 580, heatPerSecond = 3.10, price = 37700, maxCondition = 100, requiredLevel = 18 },
    tier17 = { item = 'gpu_tier17', label = 'ANX-2000',     hashrate = 148, powerDraw = 650, heatPerSecond = 3.50, price = 46200, maxCondition = 100, requiredLevel = 19 },
    tier18 = { item = 'gpu_tier18', label = 'ANX-2200',     hashrate = 178, powerDraw = 740, heatPerSecond = 3.90, price = 56600, maxCondition = 100, requiredLevel = 21 },
    tier19 = { item = 'gpu_tier19', label = 'ANX-2400',     hashrate = 214, powerDraw = 840, heatPerSecond = 4.30, price = 69400, maxCondition = 100, requiredLevel = 23 },
    tier20 = { item = 'gpu_tier20', label = 'ANX-2600 Ti',  hashrate = 256, powerDraw = 950, heatPerSecond = 4.80, price = 85000, maxCondition = 100, requiredLevel = 25 },
}

-- =========================================================================
-- MINING SKILL (XP / levels -- unlocks GPU tiers)
-- =========================================================================
-- Skill/XP/level is tracked PER RIG, not per player -- a player who owns
-- several rigs has to level each one up independently. A rig gains XP when
-- its owner collects mined BTC from it (see server/callbacks.lua's
-- collectBtc). Levelling a rig up raises which Config.GpuTiers entries are
-- buyable from THAT rig's Buy GPU panel (server/skill.lua's buyGpu callback)
-- -- installing an already-owned GPU is never gated, only purchasing new
-- ones, and only from the specific rig whose level you're spending.

Config.Skill = {
    xpPerWholeBtcCollected = 50, -- XP awarded to the rig per whole `bitcoin` item collected from it
    maxLevel = 25,

    -- XP required to REACH a given level, from the previous one:
    -- xpForLevel(level) = baseXp * level ^ growth. Raise `growth` to make
    -- higher levels take disproportionately longer.
    baseXp = 200,
    growth = 1.6,
}

-- =========================================================================
-- RIG MODELS (the placeable chassis)
-- =========================================================================
-- `model` is a placeholder GTA prop (a server rack crate) so this runs out
-- of the box -- swap it for your own streamed model once you have one, no
-- other code needs to change. `maxSlots` caps how many GPUs a chassis holds.

Config.RigModels = {
    standard = {
        item = 'mining_rig_chassis',
        label = 'Mining Rig',
        model = `prop_pc_02a`, -- real basegame PC tower (silver, blue LED) -- swap for your own prop if you want a different look
        maxSlots = 4,
        price = 12000,
    },
}

-- =========================================================================
-- MARKET (BTC sell price)
-- =========================================================================
-- Mean-reverting random walk, written to GlobalState.btc_price so every
-- client's dashboard gets live updates for free via statebag replication.

Config.Market = {
    basePrice = 45000,       -- cash per whole `bitcoin` item, the price reverts toward this
    minPrice = 20000,
    maxPrice = 90000,
    volatility = 800,         -- max random cash swing applied per update
    meanReversion = 0.05,     -- 0-1, how strongly price is pulled back toward basePrice each update
    updateIntervalMs = 60000, -- how often the price moves
}

-- =========================================================================
-- POWER
-- =========================================================================
-- 'bill'      periodic cash deduction proportional to total wattage in use;
--             rig auto-shuts-down (power_state = false) if unaffordable.
-- 'generator' requires a placed/fueled generator item (see Config.Generator)
--             supplying a wattage cap GPUs draw against; over-capacity slots
--             throttle instead of drawing cash.
-- 'both'      generator capacity first, any overflow wattage billed as cash.

Config.PowerMode = 'bill'

Config.PowerBilling = {
    intervalMs = 300000,     -- how often power cost is charged (5 min)
    costPerWattPerInterval = 0.05, -- cash charged = totalPowerDraw * this, per interval
}

-- Item names are prefixed (not just "generator_small") because that's a
-- generic enough name that it collides with other resources' items on a
-- real server (e.g. drug-lab scripts ship their own "generator_small") --
-- ox_inventory silently lets the later-loaded definition win, which breaks
-- whichever resource's export doesn't end up attached.
Config.Generator = {
    small = { item = 'btc_generator_small', label = 'Small Generator', wattageCap = 500, fuelBurnPerInterval = 5 },
    large = { item = 'btc_generator_large', label = 'Large Generator', wattageCap = 1500, fuelBurnPerInterval = 10 },
}

-- =========================================================================
-- HEAT
-- =========================================================================
-- Heat moves toward an equilibrium of (totalPowerDraw / coolingCapacity *
-- heatFactor) each tick, at changeRate per tick. Passive cooling is always
-- applied; a `cooling_fan` placeable (add your own item if wanted) can raise
-- coolingCapacity further -- wire that into rig_state.lua's equilibrium calc.

Config.Heat = {
    baseCoolingCapacity = 300, -- passive cooling, before any fan upgrades
    heatFactor = 22,           -- scales how much power draw translates into heat
    changeRate = 0.15,         -- 0-1, how fast actual heat moves toward equilibrium per tick

    warmPct = 60,      -- heatEfficiency starts ramping down past this (0-100 scale)
    criticalPct = 80,  -- per-tick chance of GPU durability damage past this
    meltdownPct = 95,  -- heatEfficiency hits 0, chance of fire + forced shutdown

    damageChancePerTick = 0.05,   -- at criticalPct, chance to damage a random installed GPU
    damageAmount = { min = 2, max = 8 }, -- durability lost per damage roll

    fireChancePerTick = 0.03,     -- at meltdownPct, chance to catch fire
    fireDestroyChance = 0.25,     -- if on fire, chance per tick a GPU is permanently destroyed

    -- A burning rig can be put out early with this item via the "Extinguish
    -- Fire" ox_target option + the Coolant Purge minigame (client/fire.lua,
    -- server/fire.lua) -- otherwise it just burns until it cools on its own.
    extinguisherItem = 'fire_extinguisher',
    extinguishCooldownMs = 15000, -- retry lockout after a failed attempt
}

-- =========================================================================
-- THEFT / RAID RISK
-- =========================================================================

Config.Theft = {
    enabled = true,

    -- Tuning for the custom "Firewall Breach" hacking minigame (a Simon-says
    -- sequence-recall grid, see web/src/components/minigames/SequenceGame.tsx)
    -- per rig security level. Config.SecurityUpgrades below raises which
    -- level a rig uses. gridSize must be a perfect square (9 = 3x3, 16 = 4x4).
    difficulty = {
        [1] = { gridSize = 9, length = 6, showDelayMs = 420, inputTimeoutMs = 6000 },
        [2] = { gridSize = 16, length = 8, showDelayMs = 340, inputTimeoutMs = 6500 },
        [3] = { gridSize = 16, length = 11, showDelayMs = 280, inputTimeoutMs = 7000 },
    },

    stealFraction = { min = 0.2, max = 0.4 }, -- fraction of banked_micro_btc stolen on success

    cooldownMs = 1800000,     -- per-rig cooldown after a successful theft (30 min)
    failCooldownMs = 300000,  -- per-rig cooldown after a failed attempt (5 min)

    alertOwner = true,        -- notify the owner (if online) when their rig is hacked
    alertPoliceOnFail = false, -- fire a generic hook event on failed attempts -- wire this to
                                -- your own dispatch system in server/theft.lua, left off by
                                -- default since it isn't tied to any one framework's dispatch

    allowGpuTheft = false,    -- optional heavier branch: physically rip a GPU out of a slot
    gpuTheftDurationMs = 15000, -- cancelable lib.progressCircle length for GPU theft
    gpuTheftConditionLoss = { min = 20, max = 40 }, -- durability lost on the stolen GPU

    maxAttemptsPerDay = 3, -- per-rig daily attempt cap across all thieves, 0 = unlimited
}

-- Raises a rig's effective security level (see Config.Theft.difficulty) and
-- lowers stealFraction. Optional -- map an ox_inventory item to a level here
-- if you want a "buy a lock" upgrade path; leave empty to skip the feature.
Config.SecurityUpgrades = {
    -- ['rig_security_lock'] = 2,
}

-- =========================================================================
-- PLACEMENT
-- =========================================================================

Config.Placement = {
    spawnRadius = 50,   -- rigs within this distance of a client are spawned in
    despawnRadius = 60, -- rigs beyond this distance are despawned client-side
    rotateStep = 45.0,  -- degrees per placement-rotation input

    -- How far out the ghost-preview raycast reaches (client/placement.lua) --
    -- this is the practical range limit on where a rig can be placed, since
    -- requireInsideZone below is unrestricted by default. Raised well past
    -- arm's reach so placement isn't boxed into a tiny radius around the
    -- player; lower it if you want rigs kept closer to hand.
    maxDistance = 30.0,

    -- Return true to allow placement at these coords, false to block it.
    -- Left as an always-true stub -- out of the box a rig can be placed
    -- anywhere the raycast above reaches, no property/zone required.
    -- Property/zone systems vary wildly between servers, so implement your
    -- own check here (e.g. "must be inside a property the player owns") if
    -- you want to restrict it, rather than this resource baking one in.
    requireInsideZone = function(coords)
        return true
    end,
}

-- =========================================================================
-- TICK / SIMULATION
-- =========================================================================

Config.Tick = {
    intervalMs = 60000, -- how often server/rig_state.lua advances every rig's simulation
    microBtcPerHashPerHour = 50, -- overall earn-rate dial: 1 hashrate unit for 1 hour = this many micro-BTC
}

-- Caps how much elapsed real-world time (in hours) counts toward mining
-- accrual after a server restart or long gap between ticks, so a rig can't
-- farm unlimited BTC just by having the server offline for a week.
Config.MaxOfflineAccrualHours = 12
