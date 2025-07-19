local palette = require("mocha")
local shape = require("gears.shape")

local theme = {}

theme.font = "JetBrainsMono Nerd Font 10"
theme.bg_systray = palette.surface0.hex
theme.icon_theme = "BeautyLine"
theme.focus_follows_mouse = false
theme.tasklist_bg_focus = palette.surface0.hex
theme.tasklist_bg_normal = "#00000000"
theme.tasklist_bg_urgent = palette.red.hex
theme.tasklist_bg_minimize = "#00000000"
theme.tasklist_shape_focus = shape.rectangle
theme.tooltip_bg = palette.surface2.hex
theme.tooltip_fg = palette.text.hex
theme.tooltip_font = theme.font
theme.tooltip_shape = shape.rounded_bar
return theme
