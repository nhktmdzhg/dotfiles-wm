local client = require('awful.client')
local placement = require('awful.placement')
local ruled = require('ruled')
local screen = require('awful.screen')

local rules = {}

function rules.init()
	ruled.client.connect_signal('request::rules', function()
		ruled.client.append_rule({
			id = 'global',
			rule = {},
			properties = {
				border_width = 0,
				focus = client.focus.filter,
				raise = true,
				screen = screen.preferred,
				placement = placement.centered,
			},
		})

		ruled.client.append_rule({
			id = 'vscode',
			rule_any = {
				class = { 'Code' },
			},
			properties = {
				maximized = true,
			},
		})

		ruled.client.append_rule({
			id = 'splash_dialog',
			rule_any = {
				type = { 'splash', 'dialog' },
			},
			properties = {
				skip_taskbar = true,
				placement = placement.centered,
			},
		})

		ruled.client.append_rule({
			id = 'menus',
			rule_any = {
				type = { 'menu', 'popup_menu', 'dropdown_menu', 'combo' },
			},
			properties = {
				skip_taskbar = true,
				placement = placement.resize_to_mouse,
			},
		})

		ruled.client.append_rule({
			id = 'gsimplecal',
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
