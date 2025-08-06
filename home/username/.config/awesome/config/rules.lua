local client = require('awful.client')
local client_ruled = require('ruled.client')
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
end

return rules
