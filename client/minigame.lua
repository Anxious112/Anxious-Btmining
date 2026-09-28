-- Bridges Lua-triggered minigames (hacking a rig, fighting a fire -- both
-- started from an ox_target option out in the world, with no dashboard
-- open) into the same NUI the dashboard uses. GpuTab.tsx runs its own
-- install minigame inline instead, since that one only ever happens while
-- the dashboard is already open and focused.

local pending = {} ---@type table<integer, any> -- requestId -> promise
local nextRequestId = 0

---@param kind 'extinguish'|'hack'
---@param difficulty table -- SweepDifficulty or SequenceDifficulty, shape must match `kind`
---@return boolean success
function RunMinigame(kind, difficulty)
    nextRequestId += 1
    local requestId = nextRequestId

    local p = promise.new()
    pending[requestId] = p

    -- DashboardOpen (client/dashboard.lua) is only true here if a player
    -- somehow triggers a world minigame while their own dashboard is open --
    -- shouldn't normally happen, but if it does, don't fight the dashboard
    -- for NUI focus or clobber it on close.
    if not DashboardOpen then
        SetNuiFocus(true, true)
    end

    SendNUIMessage({
        action = 'openMinigame',
        data = { requestId = requestId, kind = kind, difficulty = difficulty },
    })

    local success = Citizen.Await(p) == true

    if not DashboardOpen then
        SetNuiFocus(false, false)
    end

    return success
end

RegisterNUICallback('minigameResult', function(data, cb)
    local p = pending[data.requestId]
    if p then
        pending[data.requestId] = nil
        p:resolve(data.success == true)
    end
    cb(1)
end)
