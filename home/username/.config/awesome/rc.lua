-- AwesomeWM Configuration
-- Main configuration file

-- Require core libraries
local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local layout = require('awful.layout')
require('awful.autofocus')

-- Require custom modules
local autostart = require('config.autostart')
local keyboard = require('awful.keyboard')
local keys = require('config.keys')
local rules = require('config.rules')
local signals = require('config.signals')
local vars = require('config.vars')
local wibar = require('config.wibar')

-- Initialize theme
beautiful.init(filesystem.get_configuration_dir() .. 'theme.lua')

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
wibar.init(vars)
signals.init(vars, keybindings)
