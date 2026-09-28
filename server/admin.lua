-- QA/testing commands, restricted to admins via ACE. Add to your server.cfg:
--   add_ace group.admin command.btcgive allow
--   add_ace group.admin command.btcfire allow
--   add_ace group.admin command.btcrigs allow
-- (same ACE-restriction pattern as any other admin command in this codebase --
-- `true` as RegisterCommand's third arg is what makes it restricted at all).

RegisterCommand('btcgive', function(source, args)
    local item = args[1]
    local count = tonumber(args[2]) or 1

    if not item then
        exports.qbx_core:Notify(source, 'Usage: /btcgive <item> [count]', 'error')
        return
    end

    if not exports.ox_inventory:Items(item) then
        exports.qbx_core:Notify(source, ('"%s" isn\'t a real item -- check ox_inventory/data/items.lua'):format(item), 'error')
        return
    end

    local added = exports.ox_inventory:AddItem(source, item, count)
    exports.qbx_core:Notify(
        source,
        added and ('Gave %dx %s'):format(count, item) or 'Failed to add item -- inventory full?',
        added and 'success' or 'error'
    )
end, true)

-- Forces a rig straight to on-fire (bypassing the normal heat/meltdown roll)
-- so you can test the extinguish minigame, the world fire effect, and the
-- target-menu warning without waiting on the real tick loop to roll it.
-- No rig id given -- uses the caller's own first rig, so /btcfire alone is
-- enough for the common "I only have one test rig" case.
RegisterCommand('btcfire', function(source, args)
    local rigId = tonumber(args[1])

    if not rigId then
        local citizenid = GetCitizenId(source)
        local owned = citizenid and GetPlayerRigs(citizenid) or {}
        if not owned[1] then
            exports.qbx_core:Notify(source, 'You don\'t own a rig -- pass a rig id: /btcfire <id>', 'error')
            return
        end
        rigId = owned[1].id
    end

    local rig = GetRig(rigId)
    if not rig then
        exports.qbx_core:Notify(source, ('No rig with id %d'):format(rigId), 'error')
        return
    end

    rig.status.onFire = true
    rig.power_state = false
    rig.heat = math.max(rig.heat, Config.Heat.meltdownPct)
    MarkDirty(rigId)
    BroadcastRigSummaries(-1)

    exports.qbx_core:Notify(source, ('Rig #%d is now on fire'):format(rigId), 'success')
end, true)

-- Lists every rig currently in memory (id/owner/status) to the server
-- console -- there's no in-game UI for this, just a quick lookup so you know
-- what id to pass to /btcfire.
RegisterCommand('btcrigs', function(source)
    local count = 0
    for id, rig in pairs(Rigs) do
        count += 1
        local state = rig.status.onFire and 'ON FIRE' or (rig.power_state and 'running' or 'off')
        print(('[anxious_btcmining] #%d -- owner %s -- %s -- heat %.0f%%'):format(id, rig.citizenid, state, rig.heat))
    end

    exports.qbx_core:Notify(source, ('%d rig(s) -- see server console'):format(count), 'inform')
end, true)
