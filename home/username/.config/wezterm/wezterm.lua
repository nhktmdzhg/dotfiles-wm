local wezterm = require 'wezterm'
local config = {}

config.color_scheme = 'Catppuccin Mocha'
config.enable_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0, }
config.window_background_opacity = 0.9
config.font_size = 10
config.font = wezterm.font("Maple Mono NF CN")
config.use_ime = false
config.disable_default_key_bindings = true
config.automatically_reload_config = false
config.check_for_updates = false
config.keys = { {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection'
}, {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard'
}, {
    key = 't',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnTab "CurrentPaneDomain"
}, {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true }
}, {
    key = 'Tab',
    mods = 'CTRL',
    action = wezterm.action.ActivateTabRelative(1)
}, {
    key = 'Tab',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1)
}, {
    key = 'r',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ReloadConfiguration
}, {
    key = 'f',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.Search { CaseSensitiveString = '' }
} }

config.initial_cols = 117
config.initial_rows = 35
config.scrollback_lines = 10000
config.window_decorations = 'NONE'
config.enable_wayland = false
config.prefer_to_spawn_tabs = true
return config
