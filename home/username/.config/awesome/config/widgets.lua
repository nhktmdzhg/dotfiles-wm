-- Wibar widget factories plus the tasklist hover preview.

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
local poller = require('poller')
local scripts = require('scripts')
local surface = require('gears.surface')

-- Path to default SVG icon for better scaling
local noicon_path = filesystem.get_configuration_dir() .. 'awesome-switcher/noicon.svg'
local icon_dir = '/usr/share/icons/BeautyLine/apps/scalable/'

--- Sets a client icon from the BeautyLine theme, the client hint, or a fallback image.
-- @param c client Client whose icon is wanted.
-- @param icon_widget wibox.widget Image widget to update.
local function set_icon(c, icon_widget)
	if icon_widget and c then
		local icon_path = icon_dir .. c.class .. '.svg'
		if filesystem.file_readable(icon_path) then
			icon_widget.image = surface.load_uncached(icon_path)
		elseif c.icon then
			icon_widget.image = c.icon
		else
			if c.class == 'Zalo' then
				icon_widget.image = surface.load_uncached('/opt/zalo/icon.png')
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
local current_preview_widget = nil

-- Redraw the preview tile on every frame while it is shown.
preview_timer:connect_signal('timeout', function()
	if current_preview_widget then
		current_preview_widget:emit_signal('widget::updated')
	end
end)

local widgets = {}

--- Creates the tasklist with its buttons and the hover preview.
-- @param s screen Screen the tasklist is built for.
-- @return wibox.widget The tasklist, capped at 32px height.
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

						current_preview_widget = preview_widget
						if not preview_timer.started then
							preview_timer:start()
						end
					end
				end)

				-- Hide the preview when the pointer leaves the entry.
				self:connect_signal('mouse::leave', function()
					preview_wibox.visible = false
					current_preview_client = nil
					current_preview_widget = nil
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

--- Creates the logo button that opens rofi.
-- @return wibox.widget The logo widget.
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

	-- Left click opens the rofi launcher.
	arch_logo:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'rofi', '-no-lazy-grab', '-show', 'drun' })
		end
	end)

	-- Highlight the logo while the pointer is on it.
	arch_logo:connect_signal('mouse::enter', function()
		arch_logo.fg = palette.pink.hex
	end)

	-- Restore the logo color when the pointer leaves.
	arch_logo:connect_signal('mouse::leave', function()
		arch_logo.fg = palette.mauve.hex
	end)

	return arch_logo
end

--- Creates the tray widget.
-- @return wibox.widget The tray widget.
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

--- Creates the scrolling label with the focused client name, refreshed ten times a second.
-- @param s screen Screen whose wibar is shown again when no client is focused.
-- @return wibox.widget The window name widget.
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

	poller.every(0.1, function()
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
	end)

	return window_name_container
end

--- Creates the battery icon and percentage, refreshed every second.
-- @return wibox.widget The battery icon container.
-- @return wibox.widget The battery percentage container.
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

	poller.every(1, function()
		scripts.get_battery_info(function(icon, percent)
			battery_icon.text = icon
			battery_percent.text = percent .. ' %'
		end)
	end)

	return battery_icon_container, battery_percent_container
end

--- Creates the network icon and status line, refreshed every second.
-- @return wibox.widget The network icon container.
-- @return wibox.widget The network status container.
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

	-- Left click opens nmtui in a terminal.
	network_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'wezterm-gui', '-e', 'env', 'NMTUI_NO_UPDATE_CHECK=1', 'nmtui-go' })
		end
	end)

	-- Highlight the icon while the pointer is on it.
	network_icon_container:connect_signal('mouse::enter', function()
		network_icon_container.fg = palette.sky.hex
	end)

	-- Restore the icon color when the pointer leaves.
	network_icon_container:connect_signal('mouse::leave', function()
		network_icon_container.fg = palette.blue.hex
	end)

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

	poller.every(1, function()
		scripts.get_network_info(function(icon, status)
			network_icon.text = icon
			network_status.text = status
		end)
	end)

	return network_icon_container, network_status_container
end

--- Creates the volume icon and percentage, refreshed ten times a second.
-- @return wibox.widget The volume icon container.
-- @return wibox.widget The volume percentage container.
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

	-- Left click toggles mute, the wheel steps the volume.
	volume_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			scripts.set_volume('toggle')
		elseif button == 4 then
			scripts.set_volume('up')
		elseif button == 5 then
			scripts.set_volume('down')
		end
	end)

	-- Highlight the icon while the pointer is on it.
	volume_icon_container:connect_signal('mouse::enter', function()
		volume_icon_container.fg = palette.yellow.hex
	end)

	-- Restore the icon color when the pointer leaves.
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

	-- The wheel steps the volume.
	volume_percent_container:connect_signal('button::press', function(_, _, _, button)
		if button == 4 then
			scripts.set_volume('up')
		elseif button == 5 then
			scripts.set_volume('down')
		end
	end)

	poller.every(0.1, function()
		scripts.get_volume_info(function(icon, status)
			volume_icon.text = icon
			volume_percent.text = status or 'N/A'
		end)
	end)

	return volume_icon_container, volume_percent_container
end

--- Creates the calendar button, the date label and the time label, refreshed every second.
-- @return wibox.widget The calendar icon container.
-- @return wibox.widget The date container.
-- @return wibox.widget The time container.
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

	-- Left click opens gsimplecal.
	calendar_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn('gsimplecal')
		end
	end)

	-- Highlight the icon while the pointer is on it.
	calendar_icon_container:connect_signal('mouse::enter', function()
		calendar_icon_container.fg = palette.maroon.hex
	end)

	-- Restore the icon color when the pointer leaves.
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

	poller.every(1, function()
		local line_index = 0

		spawn.with_line_callback({ 'date', '+%Y年%m月%d日%n%H:%M:%S %p' }, {
			stdout = function(line)
				line_index = line_index + 1
				local text = line:gsub('%s+$', '')
				if line_index == 1 then
					date_widget.text = text
				elseif line_index == 2 then
					time_widget.text = text
				end
			end,
		})
	end)

	return calendar_icon_container, date_widget_container, time_widget_container
end

--- Creates the vertical bar used between wibar widgets.
-- @return wibox.widget The separator widget.
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

--- Creates the dashboard toggle button.
-- @return wibox.widget The toggle widget.
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

	-- Left click toggles the dashboard.
	dashboard_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			local dashboard = require('config.dashboard')
			dashboard.toggle()
		end
	end)

	-- Highlight the icon while the pointer is on it.
	dashboard_icon_container:connect_signal('mouse::enter', function()
		dashboard_icon_container.fg = palette.mauve.hex
	end)

	-- Restore the icon color when the pointer leaves.
	dashboard_icon_container:connect_signal('mouse::leave', function()
		dashboard_icon_container.fg = palette.lavender.hex
	end)

	return dashboard_icon_container
end

--- Creates the Proton VPN status label, refreshed every second.
-- @return wibox.widget The VPN status container.
function widgets.create_proton_vpn()
	local vpn_status = wibox.widget({
		widget = wibox.widget.textbox,
		font = 'Maple Mono NF CN 9',
		halign = 'center',
		valign = 'center',
	})

	local vpn_status_container = wibox.container.margin(vpn_status, 2, 2, 6, 6)
	vpn_status_container = wibox.container.background(vpn_status_container)

	tooltip({
		objects = { vpn_status_container },
		text = 'VPN Connection Status',
		mode = 'outside',
	})

	-- Left click opens the Proton VPN terminal client.
	vpn_status_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn('wezterm-gui -e pvpn')
		end
	end)

	poller.every(1, function()
		scripts.get_proton_vpn_info(function(status)
			vpn_status.text = status
			if status == '󰖂 ' then
				vpn_status_container.fg = palette.mauve.hex
			else
				vpn_status_container.fg = palette.text.hex
			end
		end)
	end)

	return vpn_status_container
end

return widgets
