fx_version "cerulean"
game "gta5"
author "Pickle Mods#0001"

ui_page "html/blank.html"

files { 
	"html/blank.html",
	"html/index.html",
	"html/style.css",
	"html/main.js",
	"html/VCR_OSD_MONO_1.001.ttf",
}

shared_scripts {
	"@es_extended/imports.lua",
    "@ox_lib/init.lua",
	"config.lua",
	"shared/*.lua"
}

client_scripts {
	"client/cursor.lua",
	"client/utils.lua",
	"client/tv.lua",
	"client/main.lua",
}

server_scripts {
	"server/*.lua"
}

lua54 'yes'