local palette = require('mocha')
local shape = require('gears.shape')

local theme = {}

theme.font = 'Maple Mono NF CN 10'
theme.bg_systray = palette.base.hex
theme.icon_theme = 'BeautyLine'
theme.tooltip_bg = palette.surface2.hex
theme.tooltip_fg = palette.text.hex
theme.tooltip_font = theme.font
theme.tooltip_shape = shape.rounded_bar

-- Notification
theme.notification_bg = palette.base.hex
theme.notification_fg = palette.text.hex
theme.notification_border_width = 6
theme.notification_border_color = palette.mantle.hex
theme.notification_shape = function(cr, w, h)
	shape.rounded_rect(cr, w, h, 12)
end

theme.notification_opacity = 0.95

theme.notification_crit_bg = palette.base.hex
theme.notification_crit_fg = palette.text.hex
theme.notification_crit_border_color = palette.peach.hex

theme.notification_font = 'Maple Mono NF CN 12'
return theme
