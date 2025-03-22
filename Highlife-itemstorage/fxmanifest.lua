fx_version 'cerulean'
game 'gta5'

author 'Highlife Development'
description 'Highlife-itemstorage'
version '1.0.0'

shared_script {
	'config.lua',
}

client_scripts {
	'client/main.lua',
	'progressbar.lua',
}

server_script {
	'server/main.lua',
	'server/exampleitem.lua',
	'@oxmysql/lib/MySQL.lua',
}

lua54 'yes'