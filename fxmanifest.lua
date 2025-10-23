fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

description 'rex-interactions'
version '2.0.0'

server_scripts {
	'server/*.lua',
}

client_scripts {
	'client/*.lua',
	'shared/*.lua'
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
}
