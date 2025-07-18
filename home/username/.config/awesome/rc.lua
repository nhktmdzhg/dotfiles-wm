-- AwesomeWM Configuration
-- Main configuration file

-- Require core libraries
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local root = require("root")
require("awful.autofocus")

-- Require custom modules
local vars = require("config.vars")
local autostart = require("config.autostart")
local keys = require("config.keys")
local rules = require("config.rules")
local wibar = require("config.wibar")
local signals = require("config.signals")

-- Initialize theme
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

-- Set layout
awful.layout.layouts = { awful.layout.suit.floating }

-- Initialize modules
autostart.init()

local keybindings = keys.init(vars)
root.keys(keybindings.globalkeys)

rules.init(keybindings)
wibar.init(vars)
signals.init(vars)
