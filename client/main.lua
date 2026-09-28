RigCache = {} ---@type table<integer, table> -- id -> lightweight summary from server/main.lua's BroadcastRigSummaries
RigProps = {} ---@type table<integer, { entity: number, data: table }>

RegisterNetEvent('anxious_btcmining:client:syncRigs', function(summaries)
    RigCache = {}
    for _, rig in ipairs(summaries) do
        RigCache[rig.id] = rig
    end
end)
