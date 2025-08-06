local client = require('awful.client')
local client_ruled = require('ruled.client')
local notification_ruled = require('ruled.notification')
local palette = require('mocha')
local placement = require('awful.placement')
local screen = require('awful.screen')

local rules = {}

function rules.init()
	client_ruled.connect_signal('request::rules', function()
		client_ruled.append_rule({
			id = 'global',
			rule = {},
			properties = {
				border_width = 0,
				focus = client.focus.filter,
				raise = true,
				screen = screen.preferred,
				placement = placement.centered,
				titlebars_enabled = false,
			},
		})
		client_ruled.append_rule({
			rule_any = {
				class = { 'Code' },
			},
			properties = {
				maximized = true,
			},
		})
		client_ruled.append_rule({
			rule_any = {
				type = { 'splash', 'dialog' },
			},
			properties = {
				skip_taskbar = true,
				placement = placement.centered,
			},
		})
		client_ruled.append_rule({
			rule_any = {
				type = { 'menu', 'popup_menu', 'dropdown_menu', 'combo' },
			},
			properties = {
				skip_taskbar = true,
				placement = placement.resize_to_mouse,
			},
		})
		client_ruled.append_rule({
			rule_any = {
				class = { 'Gsimplecal', 'gsimplecal' },
			},
			properties = {
				skip_taskbar = true,
				placement = placement.resize_to_mouse,
			},
		})
	end)

	notification_ruled.connect_signal('request::rules', function()
		notification_ruled.append_rule({
			rule = {},
			properties = {
				screen = screen.preferred,
				position = 'top_right',
				width = 444,
				height = 130,
				font = 'Maple Mono NF CN 10',
				bg = palette.base.hex,
				fg = palette.text.hex,
				border_width = 6,
				border_color = palette.base.hex,
				icon_size = 48,
				margin = 11,
				opacity = 0.97,
				timeout = 6,
			},
		})
		notification_ruled.append_rule({
			rule = { urgency = 'low' },
			properties = {
				timeout = 3,
				bg = palette.base.hex,
				fg = palette.text.hex,
			},
		})

		notification_ruled.append_rule({
			rule = { urgency = 'normal' },
			properties = {
				timeout = 6,
				bg = palette.base.hex,
				fg = palette.text.hex,
			},
		})

		notification_ruled.append_rule({
			rule = { urgency = 'critical' },
			properties = {
				timeout = 0,
				bg = palette.base.hex,
				fg = palette.text.hex,
				border_color = palette.peach.hex,
			},
		})
	end)
end

return rules
