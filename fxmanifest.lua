fx_version "cerulean"
game "gta5"
lua54 "yes"

name "tomic_territories"
author "tomiichx"
version "4.0.0"
description "Territory control for illegal organizations."

shared_scripts {
    "@es_extended/imports.lua",
    "@ox_lib/init.lua",
    "shared/config.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/**/*.lua",
}

client_scripts {
    "client/**/*.lua",
}

ui_page "web/index.html"

files {
    "web/index.html",
    "web/script.js",
    "web/style.css",
    "locales/*.json",
}

ox_libs {
    "locale",
}

dependencies {
    "es_extended",
    "ox_lib",
    "ox_inventory",
    "oxmysql",
}
