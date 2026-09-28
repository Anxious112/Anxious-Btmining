fx_version 'cerulean'
game 'gta5'

author 'Anxious'
description 'GPU rig Bitcoin mining -- placeable rigs, power/heat management, market-priced sell, theft risk'
version '1.0.0'

lua54 'yes'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/minigame.lua',
    'client/target.lua',
    'client/placement.lua',
    'client/rig_props.lua',
    'client/theft.lua',
    'client/fire.lua',
    'client/dashboard.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
    'server/migrations.lua',
    'server/rig_state.lua',
    'server/skill.lua',
    'server/main.lua',
    'server/btc_market.lua',
    'server/placement.lua',
    'server/theft.lua',
    'server/fire.lua',
    'server/access.lua',
    'server/admin.lua',
    'server/callbacks.lua',
}

files {
    'locales/*.json',
    'web/build/index.html',
    'web/build/**/*',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
    'qbx_core',
}
