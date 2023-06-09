-- Made by @Tomić#9076
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'tomiichx'
description 'Adds territories for illegal organizations to your FiveM ESX Server.'

version 'v3.1.5'

ui_page 'web/index.html'

shared_scripts {
  '@es_extended/imports.lua',
  '@ox_lib/init.lua',
  'shared.lua'
}

client_script 'client.lua'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}

files {
  'web/index.html',
  'web/script.js',
  'web/style.css'
}

dependencies {
  'rprogress',
  'ox_lib',
  'ox_inventory',
  -- '/server:6470',
  --- Ako oces stavi jer neki imaju server koji je star 3 godine.
  --- Pa im uopce nezeli otvorit ox_inventory.
}
