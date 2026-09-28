---@param rig MiningRig
---@param viewerCitizenid string?
local function toClientRig(rig, viewerCitizenid)
    local model = Config.RigModels[rig.rig_model]

    return {
        id = rig.id,
        rig_model = rig.rig_model,
        maxSlots = model and model.maxSlots or #rig.slots,
        coords = rig.coords,
        heading = rig.heading,
        slots = rig.slots,
        heat = rig.heat,
        power_state = rig.power_state,
        banked_micro_btc = rig.banked_micro_btc,
        uptime_seconds = rig.uptime_seconds,
        status = rig.status,
        xp = rig.xp,
        level = rig.level,
        -- Only the true owner (not a shared-access user) can manage who else
        -- has access -- the NUI uses this to decide whether to show the tab.
        isOwner = viewerCitizenid ~= nil and rig.citizenid == viewerCitizenid,
    }
end

---@param source number
---@param rig MiningRig?
local function hasAccess(source, rig)
    if not rig then return false end
    return HasRigAccess(rig, GetCitizenId(source))
end

---@param source number
lib.callback.register('anxious_btcmining:server:getMyRigs', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end

    local out = {}
    for _, rig in ipairs(GetPlayerRigs(citizenid)) do
        out[#out + 1] = toClientRig(rig, citizenid)
    end
    return out
end)

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:getRigDetail', function(source, rigId)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return nil end
    return toClientRig(rig, GetCitizenId(source))
end)

-- Player's own GPU items sitting in their inventory, for the "install" picker.
---@param source number
lib.callback.register('anxious_btcmining:server:getMyGpus', function(source)
    local out = {}

    for tierKey, tier in pairs(Config.GpuTiers) do
        local slots = exports.ox_inventory:GetSlotsWithItem(source, tier.item) or {}
        for _, slotData in ipairs(slots) do
            out[#out + 1] = {
                inventorySlot = slotData.slot,
                tier = tierKey,
                label = tier.label,
                durability = slotData.metadata?.durability or tier.maxCondition,
            }
        end
    end

    return out
end)

---@param source number
---@param rigId integer
---@param rigSlot integer
---@param inventorySlot integer
lib.callback.register('anxious_btcmining:server:installGpu', function(source, rigId, rigSlot, inventorySlot)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return false end
    if rig.slots[rigSlot] == nil then return false end -- out of range for this chassis
    if rig.slots[rigSlot] ~= false then return false, 'That slot is already occupied' end

    local itemSlot = exports.ox_inventory:GetSlot(source, inventorySlot)
    if not itemSlot then return false, 'Item not found' end

    local tierKey
    for key, tier in pairs(Config.GpuTiers) do
        if tier.item == itemSlot.name then
            tierKey = key
            break
        end
    end
    if not tierKey then return false, 'Not a GPU' end

    local durability = itemSlot.metadata?.durability or Config.GpuTiers[tierKey].maxCondition

    local removed = exports.ox_inventory:RemoveItem(source, itemSlot.name, 1, itemSlot.metadata, inventorySlot)
    if not removed then return false, 'Failed to remove item' end

    rig.slots[rigSlot] = { tier = tierKey, durability = durability }
    MarkDirty(rigId)

    return true, toClientRig(rig, GetCitizenId(source))
end)

---@param source number
---@param rigId integer
---@param rigSlot integer
lib.callback.register('anxious_btcmining:server:removeGpu', function(source, rigId, rigSlot)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return false end

    local slot = rig.slots[rigSlot]
    if not slot or not slot.tier then return false, 'That slot is empty' end

    local tier = GetGpuTier(slot.tier)
    if not tier then return false end

    local added = exports.ox_inventory:AddItem(source, tier.item, 1, { durability = slot.durability })
    if not added then return false, 'Your inventory is full' end

    rig.slots[rigSlot] = false
    MarkDirty(rigId)

    return true, toClientRig(rig, GetCitizenId(source))
end)

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:collectBtc', function(source, rigId)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return false end

    local wholeItems = math.floor(rig.banked_micro_btc / Config.MicroBtcPerItem)
    if wholeItems < 1 then return false, 'Nothing to collect yet' end

    local added = exports.ox_inventory:AddItem(source, Config.BtcItemName, wholeItems)
    if not added then return false, 'Your inventory is full' end

    rig.banked_micro_btc -= wholeItems * Config.MicroBtcPerItem
    MarkDirty(rigId)

    -- Mining skill XP belongs to this specific rig, not the player's account
    -- -- ties progression to actually running this rig, and means a second
    -- rig starts back at level 1.
    do
        local oldLevel, newLevel = AddRigXp(rigId, wholeItems * Config.Skill.xpPerWholeBtcCollected)
        if newLevel > oldLevel then
            exports.qbx_core:Notify(source, ('This rig leveled up! It\'s now level %d'):format(newLevel), 'success')
        end
    end

    return true, wholeItems
end)

---@param source number
---@param rigId integer
lib.callback.register('anxious_btcmining:server:togglePower', function(source, rigId)
    local rig = GetRig(rigId)
    if not hasAccess(source, rig) then return false end
    if rig.status.onFire then return false, 'This rig is on fire' end

    rig.power_state = not rig.power_state
    MarkDirty(rigId)

    return true, rig.power_state
end)

---@param source number
---@param amount integer -- whole `bitcoin` items to sell
lib.callback.register('anxious_btcmining:server:sellBtc', function(source, amount)
    if type(amount) ~= 'number' or amount < 1 then return false end

    local held = exports.ox_inventory:Search(source, 'count', Config.BtcItemName)
    if not held or held < amount then return false, 'You don\'t have that much Bitcoin' end

    local removed = exports.ox_inventory:RemoveItem(source, Config.BtcItemName, amount)
    if not removed then return false, 'Failed to remove item' end

    local payout = math.floor(amount * GlobalState.btc_price)
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        player.Functions.AddMoney(Config.Currency, payout, 'btc-sale')
    end

    return true, payout
end)

---@param source number
lib.callback.register('anxious_btcmining:server:getMarketPrice', function(source)
    return GlobalState.btc_price
end)
