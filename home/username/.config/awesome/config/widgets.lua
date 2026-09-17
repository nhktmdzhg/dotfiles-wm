-- Wibar widget factories plus the tasklist hover preview.

---@diagnostic disable: undefined-global
local gears = require('gears')
local timer = require('gears.timer')

local wibox = require('wibox')

local button = require('awful.button')
local spawn = require('awful.spawn')
local tooltip = require('awful.tooltip')
local widget = require('awful.widget')
local calendar_popup = require('awful.widget.calendar_popup')
local cairo = require('lgi').cairo

local filesystem = require('gears.filesystem')
local notifications = require('config.notifications')
local palette = require('mocha')
local poller = require('poller')
local previews = require('previews')
local scripts = require('scripts')
local surface = require('gears.surface')

-- Path to default SVG icon for better scaling
local noicon_path = filesystem.get_configuration_dir() .. 'awesome-switcher/noicon.svg'
local icon_dir = '/usr/share/icons/BeautyLine/apps/scalable/'
local ICON_FONT = 'Symbols Nerd Font 12'
local TEXT_FONT = 'Maple Mono NF CN 9'

--- Wraps a label in the margin, background and tooltip used by every wibar metric.
-- @param label wibox.widget Label to wrap.
-- @param fg string|nil Foreground of the wrapper, nil to inherit from the wibar.
-- @param tooltip_text string Tooltip shown outside the bar.
-- @return wibox.widget The background wrapper.
local function wrap_label(label, fg, tooltip_text)
	local container = wibox.container.background(wibox.container.margin(label, 2, 2, 6, 6))
	container.fg = fg

	tooltip({
		objects = { container },
		text = tooltip_text,
		mode = 'outside',
	})

	return container
end

--- Creates a centered label wrapped in the margin and background used by every wibar metric.
-- @param text string|nil Initial text, nil for metrics filled by a poll.
-- @param font string Font of the label.
-- @param fg string|nil Foreground of the wrapper, nil to inherit from the wibar.
-- @param tooltip_text string Tooltip shown outside the bar.
-- @return wibox.widget The background wrapper.
-- @return wibox.widget The label, so callers can update its text.
local function create_label(text, font, fg, tooltip_text)
	local label = wibox.widget({
		text = text,
		widget = wibox.widget.textbox,
		font = font,
		halign = 'center',
		valign = 'center',
	})

	return wrap_label(label, fg, tooltip_text), label
end

--- Creates a clock label that redraws itself on every second boundary.
-- @param format string GLib date time format, without markup characters.
-- @param tooltip_text string Tooltip shown outside the bar.
-- @return wibox.widget The background wrapper.
local function create_clock(format, tooltip_text)
	local clock = wibox.widget({
		format = format,
		refresh = 1,
		widget = wibox.widget.textclock,
		font = TEXT_FONT,
		halign = 'center',
		valign = 'center',
	})

	local container = wibox.container.background(wibox.container.margin(clock, 2, 2, 6, 6))
	container.fg = palette.text.hex

	tooltip({
		objects = { container },
		text = tooltip_text,
		mode = 'outside',
	})

	return container
end

--- Swaps the wrapper foreground while the pointer is on it.
-- @param container wibox.widget The background wrapper.
-- @param normal string Color when the pointer is away.
-- @param hover string Color when the pointer is on it.
local function connect_hover_fg(container, normal, hover)
	container:connect_signal('mouse::enter', function()
		container.fg = hover
	end)

	container:connect_signal('mouse::leave', function()
		container.fg = normal
	end)
end

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

local preview_widget = wibox.widget.base.make_widget()

preview_widget.fit = function(_, _, _)
	return 280, 180
end

preview_widget.draw = function(_, _, cairo_context, width, height)
	if not current_preview_client or not current_preview_client.valid then
		return
	end

	local surface = previews.surface(current_preview_client)

	if surface then
		local surface_width, surface_height = gears.surface.get_size(surface)
		local scale = math.min(260 / surface_width, 140 / surface_height)

		local scaled_w = surface_width * scale
		local scaled_h = surface_height * scale
		local offset_x = (width - scaled_w) / 2
		local offset_y = (height - scaled_h) / 2

		cairo_context:translate(offset_x, offset_y)
		cairo_context:scale(scale, scale)
		cairo_context:set_source_surface(surface, 0, 0)
		cairo_context:paint()
		cairo_context:scale(1 / scale, 1 / scale)
		cairo_context:translate(-offset_x, -offset_y)
	else
		surface = previews.icon(current_preview_client)
		if surface then
			local icon_width, icon_height = gears.surface.get_size(surface)
			local scale = math.min(90 / icon_width, 90 / icon_height)
			local scaled_w = icon_width * scale
			local scaled_h = icon_height * scale
			local offset_x = (width - scaled_w) / 2
			local offset_y = (height - scaled_h) / 2

			cairo_context:translate(offset_x, offset_y)
			cairo_context:scale(scale, scale)
			cairo_context:set_source_surface(surface, 0, 0)
			cairo_context:paint()
			cairo_context:scale(1 / scale, 1 / scale)
			cairo_context:translate(-offset_x, -offset_y)
		end
	end

	cairo_context:set_source_rgb(1, 1, 1)
	cairo_context:select_font_face('Maple Mono NF CN', cairo.FontSlant.NORMAL, cairo.FontWeight.NORMAL)
	cairo_context:set_font_size(12)
	local text = current_preview_client.class or current_preview_client.instance or 'Unknown'
	local text_extents = cairo_context:text_extents(text)
	cairo_context:move_to((width - text_extents.width) / 2, height - 15)
	cairo_context:show_text(text)
end

preview_wibox:setup({
	preview_widget,
	widget = wibox.container.background,
})

-- Redraw the preview tile on every frame while it is shown.
preview_timer:connect_signal('timeout', function()
	preview_widget:emit_signal('widget::updated')
end)

local widgets = {}

--- Creates the tasklist with its buttons and the hover preview.
-- @param s screen Screen the tasklist is built for.
-- @return wibox.widget The tasklist, capped at 32px height.
function widgets.create_tasklist(s)
	local tasklist_buttons = {
		button({}, 1, function(c)
			if c == client.focus then
				previews.capture(c)
			end

			c:activate({ context = 'tasklist', action = 'toggle_minimization' })
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

						local coords = mouse.coords()
						preview_wibox.x = coords.x + 10
						preview_wibox.y = coords.y + 40
						preview_wibox.visible = true

						if not preview_timer.started then
							preview_timer:start()
						end
					end
				end)

				-- Hide the preview when the pointer leaves the entry.
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

--- Creates the logo button that opens rofi.
-- @return wibox.widget The logo widget.
function widgets.create_arch_logo()
	local arch_logo = wibox.widget({
		{
			{
				markup = '',
				halign = 'center',
				valign = 'center',
				widget = wibox.widget.textbox,
				font = ICON_FONT,
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

	connect_hover_fg(arch_logo, palette.mauve.hex, palette.pink.hex)

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
		font = TEXT_FONT,
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
	local battery_icon_container, battery_icon = create_label(nil, ICON_FONT, palette.green.hex, 'Battery Status')
	local battery_percent_container, battery_percent = create_label(nil, TEXT_FONT, palette.text.hex, 'Battery percent')

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
	local network_icon_container, network_icon = create_label(nil, ICON_FONT, palette.blue.hex, 'Network Status')

	connect_hover_fg(network_icon_container, palette.blue.hex, palette.sky.hex)

	-- Left click opens nmtui in a terminal.
	network_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'wezterm-gui', '-e', 'env', 'NMTUI_NO_UPDATE_CHECK=1', 'nmtui-go' })
		end
	end)

	local network_status_container, network_status = create_label(nil, TEXT_FONT, palette.text.hex, 'SSID')

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
	local volume_icon_container, volume_icon =
			create_label(nil, ICON_FONT, palette.peach.hex, '[L] Toggle Audio Mute [S] Audio Volume +/-')

	connect_hover_fg(volume_icon_container, palette.peach.hex, palette.yellow.hex)

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

	local volume_percent_container, volume_percent =
			create_label(nil, TEXT_FONT, palette.text.hex, '[S] Audio Volume +/-')

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

--- Creates the calendar button with its month popup, the date label and the time label.
-- @return wibox.widget The calendar icon container.
-- @return wibox.widget The date container.
-- @return wibox.widget The time container.
function widgets.create_calendar()
	local calendar_icon = wibox.widget({
		widget = wibox.widget.textbox,
		font = ICON_FONT,
		halign = 'center',
		valign = 'center',
		text = '',
	})

	local calendar_icon_container = wrap_label(calendar_icon, palette.red.hex, 'Calendar')

	connect_hover_fg(calendar_icon_container, palette.red.hex, palette.maroon.hex)

	local month_calendar = calendar_popup.month({
		position = 'tr',
		margin = 10,
		start_sunday = true,
		week_numbers = false,
		bg = palette.base.hex,
		style_month = {
			bg_color = palette.base.hex,
			border_color = palette.surface1.hex,
			border_width = 2,
			padding = 10,
			shape = function(cr, width, height)
				gears.shape.rounded_rect(cr, width, height, 12)
			end,
		},
		style_header = {
			fg_color = palette.mauve.hex,
			markup = '<b>%s</b>',
		},
		style_weekday = {
			fg_color = palette.overlay1.hex,
			markup = '<b>%s</b>',
		},
		style_normal = {
			fg_color = palette.text.hex,
		},
		style_focus = {
			fg_color = palette.base.hex,
			bg_color = palette.mauve.hex,
		},
	})

	month_calendar:attach(calendar_icon_container, 'tr', { on_hover = false })

	local date_widget_container = create_clock('%Y年%m月%d日', 'Date')
	local time_widget_container = create_clock('%H:%M:%S %p', 'Time')

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
		text = '',
		font = ICON_FONT,
		halign = 'center',
		valign = 'center',
	})

	local dashboard_icon_container = wrap_label(dashboard_icon, palette.lavender.hex, 'Toggle Dashboard')

	-- Left click toggles the dashboard.
	dashboard_icon_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			local dashboard = require('config.dashboard')
			dashboard.toggle()
		end
	end)

	connect_hover_fg(dashboard_icon_container, palette.lavender.hex, palette.mauve.hex)

	return dashboard_icon_container
end

--- Creates the Proton VPN status label, refreshed every second.
-- @return wibox.widget The VPN status container.
function widgets.create_proton_vpn()
	local vpn_status_container, vpn_status = create_label(nil, TEXT_FONT, nil, 'VPN Connection Status')

	-- Left click opens the Proton VPN terminal client.
	vpn_status_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			spawn({ 'wezterm-gui', '-e', 'pvpn' })
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
