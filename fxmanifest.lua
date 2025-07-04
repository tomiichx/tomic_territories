fx_version "cerulean"
game "gta5"
lua54 "yes"

author "tomiichx"
description "Adds territories for illegal organizations to your FiveM Server."

version "v3.2.0"

shared_scripts {
	"@es_extended/imports.lua",
	"@ox_lib/init.lua",
	"shared.lua"
}

client_script "client.lua"

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server.lua"
}

ui_page "web/index.html"

files {
	"web/index.html",
	"web/script.js",
	"web/style.css"
}

dependencies {
	"ox_lib",
	"ox_inventory"
}
