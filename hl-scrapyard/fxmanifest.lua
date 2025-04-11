fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "hl-scrapyard"
description "Advanced Scrapyard System"
author 'Highlife Development'
version "2.0.0"

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/*.lua',
    'locales/en.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-skillbar'
}

escrow_ignore {
    'shared/Config.lua',
    'locales/**.lua'
}