print('^2 ____ _____ ____   __  __ _       _             ^7')
print('^2| __ )_   _/ ___| |  \\/  (_)_ __ (_)_ __   __ _ ^7')
print('^2|  _ \\ | || |     | |\\/| | | \'_ \\| | \'_ \\ / _` |^7')
print('^2| |_) || || |___  | |  | | | | | | | | | | (_| |^7')
print('^2|____/ |_| \\____| |_|  |_|_|_| |_|_|_| |_|\\__, |^7')
print('^2                                          |___/ ^7')
print('')

if GetResourceState('oxmysql') ~= 'started' then
    print('^1[anxious_btcmining] Database: oxmysql not found - script will not function^7')
end

if GetResourceState('qbx_core') == 'started' then
    print('^2[anxious_btcmining] Framework: qbx_core^7')
else
    print('^1[anxious_btcmining] Framework: qbx_core not found - this script requires qbx_core^7')
end

if GetResourceState('ox_inventory') == 'started' then
    print('^2[anxious_btcmining] Inventory: ox_inventory^7')
else
    print('^1[anxious_btcmining] Inventory: ox_inventory not found - this script requires ox_inventory^7')
end

if GetResourceState('ox_target') == 'started' then
    print('^2[anxious_btcmining] Target: ox_target^7')
else
    print('^1[anxious_btcmining] Target: ox_target not found - this script requires ox_target^7')
end

if GetResourceState('ox_lib') == 'started' then
    print('^2[anxious_btcmining] Library: ox_lib^7')
else
    print('^1[anxious_btcmining] Library: ox_lib not found - this script requires ox_lib^7')
end

local btcItem = exports.ox_inventory:Items(Config.BtcItemName)
if not btcItem then
    print(('^1[anxious_btcmining] Item "%s" (Config.BtcItemName) was not found in ox_inventory - add it before going live^7'):format(Config.BtcItemName))
end
