-- Global (not local) so client/minigame.lua can check it before grabbing or
-- releasing NUI focus for a world-triggered minigame (fire/hack) -- avoids
-- clobbering focus the dashboard is already holding, in the unlikely event
-- both are somehow open at once.
DashboardOpen = false
local currentRigId = nil

local function fetchAndSend(rigId)
    local rig = lib.callback.await('anxious_btcmining:server:getRigDetail', false, rigId)
    local skill = lib.callback.await('anxious_btcmining:server:getSkillProgress', false, rigId)
    local shop = lib.callback.await('anxious_btcmining:server:getGpuShop', false, rigId)
    local myGpus = lib.callback.await('anxious_btcmining:server:getMyGpus', false)
    -- Server returns [] for a shared-access (non-owner) viewer -- cheap
    -- enough to always fetch, the NUI only renders the tab when rig.isOwner.
    local access = lib.callback.await('anxious_btcmining:server:getRigAccess', false, rigId)

    SendNUIMessage({
        action = 'setRigData',
        data = {
            rig = rig,
            skill = skill,
            shop = shop,
            myGpus = myGpus,
            access = access,
            btcPrice = GlobalState.btc_price,
            gpuTiers = Config.GpuTiers,
        },
    })
end

---@param rigId integer
function OpenRigDashboard(rigId)
    currentRigId = rigId
    DashboardOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'setVisible', data = true })
    fetchAndSend(rigId)

    CreateThread(function()
        while DashboardOpen do
            Wait(3000)
            if DashboardOpen then
                SendNUIMessage({ action = 'setBtcPrice', data = GlobalState.btc_price })
            end
        end
    end)
end

local function closeDashboard()
    DashboardOpen = false
    currentRigId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', data = false })
end

RegisterNUICallback('closeDashboard', function(_, cb)
    closeDashboard()
    cb(1)
end)

RegisterNUICallback('installGpu', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:installGpu', false, currentRigId, data.rigSlot, data.inventorySlot)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('removeGpu', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:removeGpu', false, currentRigId, data.rigSlot)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('collectBtc', function(_, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:collectBtc', false, currentRigId)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('togglePower', function(_, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:togglePower', false, currentRigId)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('buyGpu', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:buyGpu', false, currentRigId, data.tierKey)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('sellBtc', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:sellBtc', false, data.amount)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    local players = lib.callback.await('anxious_btcmining:server:getNearbyPlayers', false, currentRigId)
    cb(players or {})
end)

RegisterNUICallback('grantAccess', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:grantAccess', false, currentRigId, data.citizenid)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)

RegisterNUICallback('revokeAccess', function(data, cb)
    local ok, result = lib.callback.await('anxious_btcmining:server:revokeAccess', false, currentRigId, data.citizenid)
    if ok then fetchAndSend(currentRigId) end
    cb({ ok = ok, message = not ok and result or nil })
end)
