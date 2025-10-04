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
local keys = require('config.keys')
local rules = require('config.rules')
local signals = require('config.signals')
local vars = require('config.vars')
local wibar = require('config.wibar')

-- Initialize theme
beautiful.init(filesystem.get_configuration_dir() .. 'theme.lua')

-- Set layout
layout.layouts = { layout.suit.floating }

-- Initialize modules
autostart.init()

local keybindings = keys.init(vars)
root.keys(keybindings.globalkeys)

rules.init(keybindings)
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
