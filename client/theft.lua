---@param rigId integer
function StartHack(rigId)
    local ok, difficultyOrReason = lib.callback.await('anxious_btcmining:server:requestHack', false, rigId)
    if not ok then
        if difficultyOrReason then
            lib.notify({ type = 'error', description = difficultyOrReason })
        end
        return
    end

    local success = RunMinigame('hack', difficultyOrReason)
    lib.callback.await('anxious_btcmining:server:resolveHack', false, rigId, success)

    lib.notify({
        type = success and 'success' or 'error',
        description = success and 'You got into the rig' or 'The hack failed',
    })
end

---@param rigId integer
function StealGpu(rigId)
    if lib.progressCircle({
        duration = Config.Theft.gpuTheftDurationMs,
        label = 'Removing GPU...',
        canCancel = true,
        disable = { move = true, combat = true },
    }) then
        local ok = lib.callback.await('anxious_btcmining:server:stealGpu', false, rigId)
        lib.notify({
            type = ok and 'success' or 'error',
            description = ok and 'GPU removed' or 'Failed to remove a GPU',
        })
    end
end
