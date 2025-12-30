---@diagnostic disable: undefined-global
local gears = require('gears')
local timer = require('gears.timer')

local wibox = require('wibox')

local button = require('awful.button')
local spawn = require('awful.spawn')
local tooltip = require('awful.tooltip')
local widget = require('awful.widget')
local cairo = require('lgi').cairo

local filesystem = require('gears.filesystem')
local notifications = require('config.notifications')
local palette = require('mocha')
local scripts = require('scripts')
local surface = require('gears.surface')

-- Path to default SVG icon for better scaling
local noicon_path = filesystem.get_configuration_dir() .. 'awesome-switcher/noicon.svg'
local icon_dir = os.getenv('HOME') .. '/.local/share/icons/BeautyLine/apps/scalable/'

local function set_icon(c, icon_widget)
	if icon_widget and c then
		local icon_path = icon_dir .. string.lower(c.class) .. '.svg'
		if filesystem.file_readable(icon_path) then
			icon_widget.image = surface.load_uncached(icon_path)
		elseif c.icon then
			icon_widget.image = c.icon
		else
			if c.class == 'legcord' then
				icon_widget.image = surface.load_uncached(icon_dir .. 'discord.svg')
			elseif c.class == 'Zalo' then
				icon_widget.image = surface.load_uncached('/opt/zalo/icon.png')
			elseif c.class == 'goneovim' then
				icon_widget.image = surface.load_uncached('/usr/share/pixmaps/goneovim.ico')
			elseif c.class == 'dev.zed.Zed' then
				icon_widget.image = surface.load_uncached('/usr/share/icons/zed.png')
			else
				icon_widget.image = surface.load_uncached(noicon_path)
			end
		end
	end
end

-- Preview wibox
local preview_wibox = wibox({
	ontop = true,
	visible = false,
	width = 300,
	height = 200,
	bg = palette.base.hex,
	border_color = palette.surface1.hex,
	border_width = 2,
})

-- Preview update timer (60 FPS)
local preview_timer = timer({
	timeout = 1 / 60, -- 60 FPS
})

local current_preview_client = nil

local widgets = {}

function widgets.create_tasklist(s)
	local tasklist_buttons = {
		button({}, 1, function(c)
			if c == client.focus then
				c.minimized = true
			else
				c:emit_signal('request::activate', 'tasklist', {
					raise = true,
				})
			end
		end),
	}

	local mytasklist = widget.tasklist({
		screen = s,
		filter = widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
		style = {
			bg_normal = palette.base.hex,
			bg_focus = palette.surface0.hex,
			fg_normal = palette.text.hex,
			fg_focus = palette.text.hex,
		},
		layout = {
			spacing = 4,
			layout = wibox.layout.fixed.horizontal,
		},
		widget_template = {
			{
				{
					id = 'icon_role',
					widget = wibox.widget.imagebox,
					forced_width = 24,
				},
				margins = 3,
				widget = wibox.container.margin,
			},
			id = 'background_role',
			widget = wibox.container.background,
			create_callback = function(self, c, _, _)
				-- Set icon when widget is created
				local icon_widget = self:get_children_by_id('icon_role')[1]
				set_icon(c, icon_widget)

				-- Add hover signals for preview
				self:connect_signal('mouse::enter', function()
					if c and c.valid and c.content then
						current_preview_client = c

						-- Create preview widget with custom draw function
						local preview_widget = wibox.widget.base.make_widget()
						preview_widget.fit = function(_, _, _)
							return 280, 180
						end
						preview_widget.draw = function(_, _, cairo_context, width, height)
							if
								current_preview_client
								and current_preview_client.valid
								and current_preview_client.content
							then
								-- Get client content as surface
								local surface = gears.surface(current_preview_client.content)
								if surface then
									-- Calculate scaling to fit preview
									local cg = current_preview_client:geometry()
									local scale_x = 260 / cg.width
									local scale_y = 140 / cg.height
									local scale = math.min(scale_x, scale_y)

									local scaled_w = cg.width * scale
									local scaled_h = cg.height * scale
									local offset_x = (width - scaled_w) / 2
									local offset_y = (height - scaled_h) / 2

									-- Draw the client content
									cairo_context:translate(offset_x, offset_y)
									cairo_context:scale(scale, scale)
									cairo_context:set_source_surface(surface, 0, 0)
									cairo_context:paint()
									cairo_context:scale(1 / scale, 1 / scale)
									cairo_context:translate(-offset_x, -offset_y)

									-- Draw app name
									cairo_context:set_source_rgb(1, 1, 1)
									cairo_context:select_font_face(
										'Maple Mono NF CN',
										cairo.FontSlant.NORMAL,
										cairo.FontWeight.NORMAL
									)
									cairo_context:set_font_size(12)
									local text = current_preview_client.class
										or current_preview_client.instance
										or 'Unknown'
									local text_extents = cairo_context:text_extents(text)
									local text_x = (width - text_extents.width) / 2
									cairo_context:move_to(text_x, height - 15)
									cairo_context:show_text(text)

									surface:finish()
								end
							end
						end

						preview_wibox:setup({
							preview_widget,
							widget = wibox.container.background,
						})

						local coords = mouse.coords()
						preview_wibox.x = coords.x + 10
						preview_wibox.y = coords.y + 40
						preview_wibox.visible = true

						-- Start live preview timer
						preview_timer:connect_signal('timeout', function()
							if preview_widget then
								preview_widget:emit_signal('widget::updated')
							end
						end)
						preview_timer:start()
					end
				end)

				self:connect_signal('mouse::leave', function()
					preview_wibox.visible = false
					current_preview_client = nil
					preview_timer:stop()
				end)
			end,
			update_callback = function(self, c, _, _)
				-- Update icon when client changes
				local icon_widget = self:get_children_by_id('icon_role')[1]
				set_icon(c, icon_widget)
			end,
		},
	})

	return wibox.container.constraint(mytasklist, 'exact', nil, 32)
end

function widgets.create_arch_logo()
	local arch_logo = wibox.widget({
		{
			{
				markup = '',
				halign = 'center',
				valign = 'center',
				widget = wibox.widget.textbox,
				font = 'JetBrainsMono Nerd Font Mono 20',
			},
			margins = 2,
			widget = wibox.container.margin,
		},
		widget = wibox.container.background,
		fg = palette.mauve.hex,
	})

	tooltip({
		objects = { arch_logo },
		text = '[L] Main Menu',
		mode = 'outside',
	})

	arch_logo:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'env', 'XMODIFIERS=@im=none', 'rofi', '-no-lazy-grab', '-show', 'drun' })
		end
	end)

	arch_logo:connect_signal('mouse::enter', function()
		arch_logo.fg = palette.pink.hex
	end)

	arch_logo:connect_signal('mouse::leave', function()
		arch_logo.fg = palette.mauve.hex
	end)

	return arch_logo
end

function widgets.create_systray()
	local mysystray = wibox.widget({
		wibox.widget.systray(),
		left = 2,
		right = 2,
		top = 2,
		bottom = 2,
		widget = wibox.container.margin,
	})

	return mysystray
end

function widgets.create_window_name(s)
	local window_name = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local scroll_container = wibox.container.scroll.horizontal(window_name, 2, 50, 0)
	scroll_container:set_max_size(300)
	scroll_container:set_step_function(wibox.container.scroll.step_functions.linear_back_and_forth)

	local window_name_container = wibox.container.margin(scroll_container, 2, 2, 6, 6)
	window_name_container = wibox.container.background(window_name_container)
	window_name_container.fg = palette.text.hex

	tooltip({
		objects = { window_name_container },
		text = 'Window Name',
		mode = 'outside',
	})

	timer({
		timeout = 0.1,
		autostart = true,
		call_now = true,
		callback = function()
			local c = client.focus
			local name = ''
			if c then
				name = c.name
			else
				name = 'No focused window'
				s.mywibar.visible = true
				if notifications.is_paused() then
					notifications.pause()
				else
					notifications.unpause()
				end
			end
			window_name.text = name
		end,
	})

	return window_name_container
end

function widgets.create_battery()
	local battery_icon = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'JetBrainsMono Nerd Font Mono 16',
		halign = 'center',
		valign = 'center',
	})

	local battery_icon_container = wibox.container.margin(battery_icon, 2, 2, 6, 6)
	battery_icon_container = wibox.container.background(battery_icon_container)
	battery_icon_container.fg = palette.green.hex

	tooltip({
		objects = { battery_icon_container },
		text = 'Battery Status',
		mode = 'outside',
	})

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_battery_icon(function(icon)
				battery_icon.text = icon
			end)
		end,
	})

	local battery_percent = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local battery_percent_container = wibox.container.margin(battery_percent, 2, 2, 6, 6)
	battery_percent_container = wibox.container.background(battery_percent_container)
	battery_percent_container.fg = palette.text.hex

	tooltip({
		objects = { battery_percent_container },
		text = 'Battery percent',
		mode = 'outside',
	})

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_battery_percent(function(percent)
				if percent then
					battery_percent.text = percent .. ' %'
				else
					battery_percent.text = 'N/A'
				end
			end)
		end,
	})

	return battery_icon_container, battery_percent_container
end

function widgets.create_network()
	local network_icon = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'JetBrainsMono Nerd Font Mono 16',
		halign = 'center',
		valign = 'center',
	})

	local network_icon_container = wibox.container.margin(network_icon, 2, 2, 6, 6)
	network_icon_container = wibox.container.background(network_icon_container)
	network_icon_container.fg = palette.blue.hex

	tooltip({
		objects = { network_icon_container },
		text = 'Network Status',
		mode = 'outside',
	})

	network_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'st', '-e', 'nmcurse' })
		end
	end)

	network_icon_container:connect_signal('mouse::enter', function()
		network_icon_container.fg = palette.sky.hex
	end)

	network_icon_container:connect_signal('mouse::leave', function()
		network_icon_container.fg = palette.blue.hex
	end)

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_network_info(0, function(icon)
				network_icon.text = icon
			end)
		end,
	})

	local network_status = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local network_status_container = wibox.container.margin(network_status, 2, 2, 6, 6)
	network_status_container = wibox.container.background(network_status_container)
	network_status_container.fg = palette.text.hex

	tooltip({
		objects = { network_status_container },
		text = 'SSID',
		mode = 'outside',
	})

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_network_info(1, function(status)
				network_status.text = status
			end)
		end,
	})

	return network_icon_container, network_status_container
end

function widgets.create_volume()
	local volume_icon = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'JetBrainsMono Nerd Font Mono 16',
		halign = 'center',
		valign = 'center',
	})

	local volume_icon_container = wibox.container.margin(volume_icon, 2, 2, 6, 6)
	volume_icon_container = wibox.container.background(volume_icon_container)
	volume_icon_container.fg = palette.peach.hex

	tooltip({
		objects = { volume_icon_container },
		text = '[L] Toggle Audio Mute [S] Audio Volume +/-',
		mode = 'outside',
	})

	timer({
		timeout = 0.1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_volume_info(2, function(icon)
				volume_icon.text = icon
			end)
		end,
	})

	volume_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			scripts.get_volume_info(0, nil)
		elseif button == 4 then
			scripts.get_volume_info(1, nil)
		elseif button == 5 then
			scripts.get_volume_info(-1, nil)
		end
	end)

	volume_icon_container:connect_signal('mouse::enter', function()
		volume_icon_container.fg = palette.yellow.hex
	end)

	volume_icon_container:connect_signal('mouse::leave', function()
		volume_icon_container.fg = palette.peach.hex
	end)

	local volume_percent = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local volume_percent_container = wibox.container.margin(volume_percent, 2, 2, 6, 6)
	volume_percent_container = wibox.container.background(volume_percent_container)
	volume_percent_container.fg = palette.text.hex

	tooltip({
		objects = { volume_percent_container },
		text = '[S] Audio Volume +/-',
		mode = 'outside',
	})

	timer({
		timeout = 0.1,
		autostart = true,
		call_now = true,
		callback = function()
			scripts.get_volume_info(3, function(status)
				volume_percent.text = status or 'N/A'
			end)
		end,
	})

	volume_percent_container:connect_signal('button::press', function(_, _, _, button)
		if button == 4 then
			scripts.get_volume_info(1, nil)
		elseif button == 5 then
			scripts.get_volume_info(-1, nil)
		end
	end)

	return volume_icon_container, volume_percent_container
end

function widgets.create_calendar()
	local calendar_icon = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'JetBrainsMono Nerd Font Mono 16',
		halign = 'center',
		valign = 'center',
		text = '',
	})

	local calendar_icon_container = wibox.container.margin(calendar_icon, 2, 2, 6, 6)
	calendar_icon_container = wibox.container.background(calendar_icon_container)
	calendar_icon_container.fg = palette.red.hex

	tooltip({
		objects = { calendar_icon_container },
		text = 'Calendar',
		mode = 'outside',
	})

	calendar_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn('gsimplecal')
		end
	end)

	calendar_icon_container:connect_signal('mouse::enter', function()
		calendar_icon_container.fg = palette.maroon.hex
	end)

	calendar_icon_container:connect_signal('mouse::leave', function()
		calendar_icon_container.fg = palette.red.hex
	end)

	local date_widget = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local date_widget_container = wibox.container.margin(date_widget, 2, 2, 6, 6)
	date_widget_container = wibox.container.background(date_widget_container)
	date_widget_container.fg = palette.text.hex

	tooltip({
		objects = { date_widget_container },
		text = 'Date',
		mode = 'outside',
	})

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			spawn.easy_async({ 'date', '+%Y年%m月%d日' }, function(stdout)
				date_widget.text = stdout:gsub('%s+$', '')
			end)
		end,
	})

	local time_widget = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local time_widget_container = wibox.container.margin(time_widget, 2, 2, 6, 6)
	time_widget_container = wibox.container.background(time_widget_container)
	time_widget_container.fg = palette.text.hex

	tooltip({
		objects = { time_widget_container },
		text = 'Time',
		mode = 'outside',
	})

	timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			spawn.easy_async({ 'date', '+%H:%M:%S %p' }, function(stdout)
				time_widget.text = stdout:gsub('%s+$', '')
			end)
		end,
	})

	return calendar_icon_container, date_widget_container, time_widget_container
end

function widgets.create_simple_separator()
	local separator = wibox.widget({
		markup = '|',
		halign = 'center',
		valign = 'center',
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 15',
	})

	local separator_container = wibox.container.background(separator)
	separator_container.fg = palette.overlay0.hex

	return separator_container
end

function widgets.create_dashboard_toggle()
	local dashboard_icon = wibox.widget({
		widget = wibox.widget.textbox,
		text = '󰕮',
		font = 'JetBrainsMono Nerd Font Mono 16',
		halign = 'center',
		valign = 'center',
	})

	local dashboard_icon_container = wibox.container.margin(dashboard_icon, 2, 2, 6, 6)
	dashboard_icon_container = wibox.container.background(dashboard_icon_container)
	dashboard_icon_container.fg = palette.lavender.hex

	tooltip({
		objects = { dashboard_icon_container },
		text = 'Toggle Dashboard',
		mode = 'outside',
	})

	dashboard_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			local dashboard = require('config.dashboard')
			dashboard.toggle()
		end
	end)

	dashboard_icon_container:connect_signal('mouse::enter', function()
		dashboard_icon_container.fg = palette.mauve.hex
	end)

	dashboard_icon_container:connect_signal('mouse::leave', function()
		dashboard_icon_container.fg = palette.lavender.hex
	end)

	return dashboard_icon_container
end

return widgets
