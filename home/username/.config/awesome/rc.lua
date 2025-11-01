---@diagnostic disable: undefined-global
-- AwesomeWM Configuration
-- Main configuration file

-- Require core libraries
local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local layout = require('awful.layout')
require('awful.autofocus')

-- Require custom modules
local autostart = require('config.autostart')
local gears = require('gears')
local keyboard = require('awful.keyboard')
local keys = require('config.keys')
local mouse = require('awful.mouse')
local rules = require('config.rules')
local signals = require('config.signals')
local vars = require('config.vars')
local wallpaper = require('awful.wallpaper')
local wibar = require('config.wibar')
local wibox = require('wibox')

-- Initialize theme
beautiful.init(filesystem.get_configuration_dir() .. 'theme.lua')

-- Set wallpaper
screen.connect_signal('request::wallpaper', function(s)
	wallpaper({
		screen = s,
		widget = {
			{
				image = vars.wallpaper,
				upscale = true,
				downscale = true,
				widget = wibox.widget.imagebox,
			},
			valign = 'center',
			halign = 'center',
			tiled = false,
			widget = wibox.container.tile,
		},
	})
end)

-- Set layout
tag.connect_signal('request::default_layouts', function()
	layout.append_default_layouts({
		layout.suit.floating,
	})
end)

-- Initialize modules
autostart.init()

local keybindings = keys.init(vars)
keyboard.append_global_keybindings(keybindings.globalkeys)

rules.init()
client.connect_signal('request::default_keybindings', function()
	keyboard.append_client_keybindings(keybindings.clientkeys)
end)

client.connect_signal('request::default_mousebindings', function()
	mouse.append_client_mousebindings(keybindings.clientbuttons)
end)

wibar.init(vars)
signals.init(vars)

collectgarbage('setpause', 110)
collectgarbage('setstepmul', 1000)

gears.timer({
	timeout = 5,
	autostart = true,
	callback = function()
		collectgarbage('collect')
	end,
})
