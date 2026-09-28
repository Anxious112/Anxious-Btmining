---@param rigId integer
function StartExtinguish(rigId)
    local ok, difficultyOrReason = lib.callback.await('anxious_btcmining:server:requestExtinguish', false, rigId)
    if not ok then
        if difficultyOrReason then
            lib.notify({ type = 'error', description = difficultyOrReason })
        end
        return
    end

    local success = RunMinigame('extinguish', difficultyOrReason)
    lib.callback.await('anxious_btcmining:server:resolveExtinguish', false, rigId, success)

    lib.notify({
        type = success and 'success' or 'error',
        description = success and 'Fire\'s out' or 'The fire got away from you',
    })
end
