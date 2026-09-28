---@param source number
---@return string?
function GetCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.citizenid
end

local function decodeRow(row)
    local coords = json.decode(row.coords)
    local status = json.decode(row.status)

    return {
        id = row.id,
        citizenid = row.citizenid,
        rig_model = row.rig_model,
        coords = vector3(coords.x, coords.y, coords.z),
        heading = row.heading,
        slots = json.decode(row.slots),
        heat = row.heat,
        power_state = row.power_state == 1,
        banked_micro_btc = row.banked_micro_btc,
        uptime_seconds = row.uptime_seconds,
        last_tick = row.last_tick,
        status = status,
        xp = row.xp,
        level = row.level,
        shared_access = row.shared_access and json.decode(row.shared_access) or {},
    }
end

local function loadAllRigs()
    local rows = MySQL.query.await('SELECT * FROM `mining_rigs`') or {}

    for _, row in ipairs(rows) do
        local rig = decodeRow(row)
        -- A rig that was mid-flight when the server last stopped should catch
        -- up on the time it missed, same as any other tick -- just clamp
        -- last_tick to "now" first isn't right, we want advanceRig (called on
        -- the next real tick) to see the true gap and apply the offline cap.
        Rigs[rig.id] = rig
    end

    print(('^2[anxious_btcmining] Loaded %d mining rig(s)^7'):format(#rows))
end

---@param citizenid string
---@param rigModel string
---@param coords vector3
---@param heading number
---@return integer? id
function CreateRig(citizenid, rigModel, coords, heading)
    local model = Config.RigModels[rigModel]
    if not model then return nil end

    local slots = {}
    for i = 1, model.maxSlots do
        slots[i] = false
    end

    local status = { damaged = false, onFire = false, seized = false }
    local now = os.time()

    local id = MySQL.insert.await([[
        INSERT INTO `mining_rigs`
            (`citizenid`, `rig_model`, `coords`, `heading`, `slots`, `heat`, `power_state`, `banked_micro_btc`, `uptime_seconds`, `last_tick`, `status`)
        VALUES (?, ?, ?, ?, ?, 0, 1, 0, 0, ?, ?)
    ]], {
        citizenid, rigModel,
        json.encode({ x = coords.x, y = coords.y, z = coords.z }), heading,
        json.encode(slots), now, json.encode(status),
    })

    if not id then return nil end

    Rigs[id] = {
        id = id,
        citizenid = citizenid,
        rig_model = rigModel,
        coords = coords,
        heading = heading,
        slots = slots,
        heat = 0,
        power_state = true,
        banked_micro_btc = 0,
        uptime_seconds = 0,
        last_tick = now,
        status = status,
        xp = 0,
        level = 1,
        shared_access = {},
    }

    return id
end

---@param id integer
function DeleteRig(id)
    Rigs[id] = nil
    MySQL.update.await('DELETE FROM `mining_rigs` WHERE `id` = ?', { id })
end

-- Lightweight world-prop summary -- only what client/rig_props.lua needs to
-- decide what to stream in/out by distance. Full per-rig state (slots, heat,
-- BTC balance) only goes to the owner, via server/callbacks.lua.
---@param target number -- -1 for all players, or a specific source
function BroadcastRigSummaries(target)
    local summaries = {}
    for id, rig in pairs(Rigs) do
        summaries[#summaries + 1] = {
            id = id,
            citizenid = rig.citizenid, -- only used client-side to show the right target option (owner vs not)
            shared_access = rig.shared_access, -- same, for authorized-but-not-owner players
            rig_model = rig.rig_model,
            coords = rig.coords,
            heading = rig.heading,
            status = rig.status,
        }
    end

    TriggerClientEvent('anxious_btcmining:client:syncRigs', target, summaries)
end

AddEventHandler('playerJoining', function()
    BroadcastRigSummaries(source)
end)

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(500)
    end

    RunMigrations()
    loadAllRigs()

    -- playerJoining only covers players connecting AFTER this resource is
    -- up -- anyone already online when this resource (re)starts has their
    -- client-side RigCache reset to empty by the restart and never gets a
    -- fresh sync otherwise, leaving every rig un-interactable until they
    -- rejoin. Push once to everyone already connected to cover that case.
    BroadcastRigSummaries(-1)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Persist final state for every rig, not just whatever was already
    -- flagged dirty, so a restart never silently drops progress.
    for id in pairs(Rigs) do
        MarkDirty(id)
    end
    FlushDirty()
end)
