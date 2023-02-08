-- Made by @Tomić#9076
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'tomiichx'
description 'Territory System for Gangs'

version 'v2.0.1'

ui_page "web/index.html"

shared_scripts {
  '@es_extended/imports.lua',
  '@ox_lib/init.lua',
  'shared.lua'
}

files {
  "web/index.html",
  "web/script.js",
  "web/style.css",
}


client_script 'client.lua'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}