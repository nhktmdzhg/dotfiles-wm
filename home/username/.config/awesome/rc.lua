-- AwesomeWM Configuration
-- Main configuration file

-- Require core libraries
local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local layout = require('awful.layout')
local root = require('root')
require('awful.autofocus')

-- Require custom modules
local autostart = require('config.autostart')
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
