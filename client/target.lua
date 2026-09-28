---@param obj number
---@param rig table -- lightweight summary from RigCache (id, rig_model, coords, heading, status, shared_access)
function AttachRigTarget(obj, rig)
    local myCitizenid = QBX.PlayerData.citizenid
    local hasAccess = myCitizenid ~= nil and rig.citizenid ~= nil and myCitizenid == rig.citizenid

    -- This is a client-side check purely to decide which menu option to
    -- show -- server/callbacks.lua's HasRigAccess is the real gate on every
    -- action, same trust split this resource already uses for isOwner.
    if not hasAccess and myCitizenid and rig.shared_access then
        for _, granted in ipairs(rig.shared_access) do
            if granted == myCitizenid then
                hasAccess = true
                break
            end
        end
    end

    local options = {}

    if rig.status and rig.status.onFire then
        options[#options + 1] = {
            name = 'btcmining_extinguish_' .. rig.id,
            icon = 'fa-solid fa-fire-extinguisher',
            label = 'Extinguish Fire',
            distance = 2.5,
            items = Config.Heat.extinguisherItem,
            onSelect = function()
                StartExtinguish(rig.id)
            end,
        }
    elseif hasAccess then
        options[#options + 1] = {
            name = 'btcmining_access_' .. rig.id,
            icon = 'fa-solid fa-server',
            label = 'Access Panel',
            distance = 2.5,
            onSelect = function()
                OpenRigDashboard(rig.id)
            end,
        }
    else
        options[#options + 1] = {
            name = 'btcmining_hack_' .. rig.id,
            icon = 'fa-solid fa-laptop-code',
            label = 'Hack Rig',
            distance = 2.5,
            onSelect = function()
                StartHack(rig.id)
            end,
        }

        if Config.Theft.allowGpuTheft then
            options[#options + 1] = {
                name = 'btcmining_stealgpu_' .. rig.id,
                icon = 'fa-solid fa-microchip',
                label = 'Remove a GPU',
                distance = 2.5,
                onSelect = function()
                    StealGpu(rig.id)
                end,
            }
        end
    end

    exports.ox_target:addLocalEntity(obj, options)
end
