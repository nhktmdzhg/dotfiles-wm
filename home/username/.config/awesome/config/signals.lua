local awful = require('awful')
local beautiful = require('beautiful')
local keyboard = require('awful.keyboard')
local mouse = require('awful.mouse')
local naughty = require('naughty')
local palette = require('mocha')
local spawn = require('awful.spawn')
local table = require('gears.table')
local wallpaper = require('awful.wallpaper')
local wibox = require('wibox')

local signals = {}

local dunst_paused = false

local function clamp(x, min, max)
	return math.max(min, math.min(max, x))
end

function signals.toggle_dunst()
	dunst_paused = not dunst_paused
	if client.focus.fullscreen then
		return
	end
	if dunst_paused then
		spawn({ 'dunstctl', 'set-paused', 'true' })
	else
		spawn({ 'dunstctl', 'set-paused', 'false' })
	end
end

function signals.is_dunst_paused()
	return dunst_paused
end

function signals.init(vars, keybindings)
	local margin_top = vars.margin_top
	local margin_bottom = vars.margin_bottom
	local margin_left = vars.margin_left
	local margin_right = vars.margin_right

	-- Signals
	client.connect_signal('request::manage', function(c)
		local wa = c.screen.workarea
		if not c.fullscreen then
			c:geometry({
				x = math.max(wa.x + margin_left, c.x),
				y = math.max(wa.y + margin_top, c.y),
				width = math.min(wa.width - margin_left - margin_right, c.width),
				height = math.min(wa.height - margin_top - margin_bottom, c.height),
			})
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		else
			spawn({ 'dunstctl', 'set-paused', 'true' })
		end
	end)

	client.connect_signal('focus', function(c)
		local screen = c.screen
		if c.fullscreen then
			screen.mywibar.visible = false
			spawn({ 'dunstctl', 'set-paused', 'true' })
		else
			screen.mywibar.visible = true
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		end
	end)

	client.connect_signal('request::geometry', function(c)
		local wa = c.screen.workarea

		if c.fullscreen then
			return
		elseif c.maximized then
			c:geometry({
				x = wa.x + margin_left,
				y = wa.y + margin_top,
				width = wa.width - margin_left - margin_right,
				height = wa.height - margin_top - margin_bottom,
			})
		else
			c:geometry({
				x = clamp(c.x, wa.x + margin_left, wa.x + wa.width - margin_right - c.width),
				y = clamp(c.y, wa.y + margin_top, wa.y + wa.height - margin_bottom - c.height),
				width = math.min(wa.width - margin_left - margin_right, c.width),
				height = math.min(wa.height - margin_top - margin_bottom, c.height),
			})
		end
	end)

	client.connect_signal('property::fullscreen', function(c)
		local screen = c.screen
		if c == screen.selected_tag then
			return
		end

		if c.fullscreen then
			screen.mywibar.visible = false
			spawn({ 'dunstctl', 'set-paused', 'true' })
		else
			screen.mywibar.visible = true
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		end
	end)

	client.connect_signal('request::default_mousebindings', function()
		mouse.append_client_mousebindings(keybindings.clientbuttons)
	end)

	client.connect_signal('request::default_keybindings', function()
		keyboard.append_client_keybindings(keybindings.clientkeys)
	end)

	screen.connect_signal('request::wallpaper', function(s)
		wallpaper({
			screen = s,
			widget = {
				{
					image = beautiful.wallpaper,
					upscale = true,
					downscale = true,
					widget = wibox.widget.imagebox,
				},
				valign = 'center',
				halign = 'center',
				tiled = false,
				widget = wibox.container.tile,
			},
		})
	end)

	local dunst_template = {
		{
			{
				{
					{
						{
							id = 'icon_role',
							widget = wibox.widget.imagebox,
							resize = true,
							forced_width = 48,
							forced_height = 48,
						},
						{
							{
								{
									id = 'title_role',
									font = 'Maple Mono NF CN 9 Bold',
									markup = function(self, title)
										return string.format(
											"<span size='x-large' font_desc='Maple Mono NF CN 9' weight='bold' foreground='#f9f9f9'>%s</span>",
											title or ''
										)
									end,
									widget = wibox.widget.textbox,
								},
								-- Message body
								{
									id = 'message_role',
									font = 'Maple Mono NF CN 10',
									widget = wibox.widget.textbox,
								},
								layout = wibox.layout.fixed.vertical,
								spacing = 4,
							},
							left = 11,
							right = 11,
							widget = wibox.container.margin,
						},
						layout = wibox.layout.fixed.horizontal,
						spacing = 11,
					},

					{
						id = 'progress_role',
						max_value = 100,
						value = 0,
						forced_height = 5,
						background_color = palette.base.hex,
						color = palette.peach.hex,
						widget = wibox.widget.progressbar,
						visible = false,
					},
					layout = wibox.layout.fixed.vertical,
				},
				margins = 11,
				widget = wibox.container.margin,
			},
			bg = palette.base.hex,
			fg = palette.text.hex,
			shape_border_width = 6,
			shape_border_color = palette.base.hex,
			widget = wibox.container.background,
		},
		forced_width = 444,
		forced_height = 130,
		widget = wibox.container.constraint,
	}

	naughty.connect_signal('request::display', function(n)
		local box = naughty.layout.box({
			notification = n,
			widget_template = dunst_template,
			position = 'top_right',
			screen = awful.screen.preferred,
			bg = n.bg or palette.base.hex,
			fg = n.fg or palette.text.hex,
			border_width = 6,
			border_color = n.urgency == 'critical' and palette.peach.hex or palette.base.hex,
			opacity = 0.97,
		})

		box:buttons(table.join(
			awful.button({}, 1, function()
				n:destroy(naughty.notification_closed_reason.dismissed_by_user)
			end),
			awful.button({}, 2, function()
				if n.run then
					n:run()
				end
				n:destroy(naughty.notification_closed_reason.dismissed_by_user)
			end),
			awful.button({}, 3, function()
				for _, notif in ipairs(naughty.active) do
					notif:destroy(naughty.notification_closed_reason.dismissed_by_user)
				end
			end)
		))
	end)
end

return signals
