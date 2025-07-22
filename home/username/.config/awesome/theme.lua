local palette = require("mocha")
local shape = require("gears.shape")

local theme = {}

theme.font = "Maple Mono NF CN 10"
theme.bg_systray = palette.base.hex
theme.icon_theme = "BeautyLine"
theme.focus_follows_mouse = false
theme.tooltip_bg = palette.surface2.hex
theme.tooltip_fg = palette.text.hex
theme.tooltip_font = theme.font
theme.tooltip_shape = shape.rounded_bar
return theme
