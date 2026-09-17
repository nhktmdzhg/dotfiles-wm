-- Right-side dashboard wibox: launcher grid, media controls, sliders and power buttons.

---@diagnostic disable: undefined-global
local awful = require('awful')
local gears = require('gears')
local images = require('images')
local palette = require('mocha')
local poller = require('poller')
local wibox = require('wibox')

local dashboard = {}

local dashboard_wibox = nil
local dashboard_visible = false

local avatar_path = os.getenv('HOME') .. '/.config/awesome/avatar.png'
local launcher_list = {
	{ name = 'Wezterm', icon = '', command = { 'wezterm-gui' } },
	{ name = 'Firefox', icon = '', command = { 'firefox' } },
	{ name = 'Yazi', icon = '', command = { 'wezterm-gui', '-e', 'yazi' } },
	{ name = 'Helix', icon = '', command = { 'wezterm-gui', '-e', 'helix' } },
	{ name = 'Open config', icon = '', command = { 'sh', '-c', 'wezterm-gui start --cwd ~/.config/awesome/ -- helix rc.lua' } },
	{
		name = 'HSR',
		icon = '',
		command = { 'env', 'MANGOHUD=1', 'bottles-cli', 'run', '-p', 'HSR', '-b', 'michos' },
	},
}

--- Creates the avatar picture shown at the top of the dashboard.
-- @return wibox.widget The avatar widget.
local function create_avatar_widget()
	return wibox.widget({
		{
			image = images.scaled(avatar_path, 200, 200),
			resize = true,
			forced_height = 100,
			forced_width = 100,
			widget = wibox.widget.imagebox,
		},
		margins = 20,
		widget = wibox.container.margin,
	})
end

--- Creates the greeting label shown next to the avatar.
-- @return wibox.widget The name widget.
local function create_name_widget()
	return wibox.widget({
		{
			text = 'Hello, 長夜月',
			font = 'Maple Mono NF CN 18',
			halign = 'center',
			widget = wibox.widget.textbox,
		},
		fg = palette.text.hex,
		widget = wibox.container.background,
	})
end

--- Creates the avatar and greeting row with its margins.
-- @return wibox.widget The header row.
local function create_info_rows()
	return {
		{
			create_avatar_widget(),
			create_name_widget(),
			spacing = 10,
			layout = wibox.layout.fixed.horizontal,
		},
		margins = 20,
		widget = wibox.container.margin,
	}
end

--- Creates one launcher button that runs its command on left click.
-- @param launcher table Entry of launcher_list, with name, icon and command fields.
-- @return wibox.widget The launcher button.
local function create_launcher_widget(launcher)
	local launcher_widget = wibox.widget({
		{
			text = launcher.icon,
			font = 'Symbols Nerd Font 14',
			widget = wibox.widget.textbox,
		},
		{
			text = launcher.name,
			font = 'Maple Mono NF CN 14',
			widget = wibox.widget.textbox,
		},
		layout = wibox.layout.fixed.horizontal,
		spacing = 10,
	})

	local launcher_container = wibox.widget({
		{
			launcher_widget,
			left = 10,
			right = 10,
			widget = wibox.container.margin,
		},
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})
	-- Left click runs the launcher command.
	launcher_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			awful.spawn(launcher.command)
		end
	end)

	-- Highlight the row while the pointer is on it.
	launcher_container:connect_signal('mouse::enter', function()
		launcher_container.bg = palette.surface1.hex
	end)

	-- Restore the row background when the pointer leaves.
	launcher_container:connect_signal('mouse::leave', function()
		launcher_container.bg = palette.surface0.hex
	end)

	return launcher_container
end

--- Creates the two-column grid holding every launcher button.
-- @return wibox.widget The launcher grid.
local function create_launcher_grid()
	local widgets = {}
	for _, launcher in ipairs(launcher_list) do
		table.insert(widgets, create_launcher_widget(launcher))
	end

	local grid_content = {
		layout = wibox.layout.grid,
		spacing = 10,
		forced_num_cols = 2,
	}
	for i, widget in ipairs(widgets) do
		grid_content[i] = widget
	end

	return wibox.widget({
		grid_content,
		margins = 20,
		widget = wibox.container.margin,
	})
end

--- Creates the scrolling label that polls playerctl for the current track.
-- @return wibox.widget The scroll container wrapping the label.
local function create_current_playing()
	local current_widget = wibox.widget({
		{
			font = 'Maple Mono NF CN 12',
			widget = wibox.widget.textbox,
			halign = 'center',
			valign = 'center',
		},
		fg = palette.text.hex,
		widget = wibox.container.background,
	})

	local scroll_container = wibox.container.scroll.horizontal(current_widget, 2, 50, 0)

	scroll_container:set_max_size(400)
	scroll_container:set_step_function(wibox.container.scroll.step_functions.linear_back_and_forth)

	poller.every(1, function()
		local song = ''

		awful.spawn.with_line_callback({ 'playerctl', 'metadata', '--format', '{{ title }} - {{ artist }}' }, {
			stdout = function(line)
				song = line
			end,
			output_done = function()
				local current_song = song:gsub('%s+$', '')
				if current_song == '' then
					current_song = 'No song playing'
				else
					current_song = 'Now Playing: ' .. current_song
				end
				if current_widget.widget.text ~= current_song then
					current_widget.widget.text = current_song
					scroll_container:emit_signal('widget::redraw_needed')
				end
			end,
		})
	end)

	return scroll_container
end

--- Creates a media control button.
-- @param id string Widget id, used to tell the buttons apart.
-- @param icon string Icon glyph to draw.
-- @param command string|table Command run on left click.
-- @return wibox.widget The button.
local function create_media_button(id, icon, command)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = 'Maple Mono NF CN 16',
				halign = 'center',
				widget = wibox.widget.textbox,
			},
			margins = 10,
			widget = wibox.container.margin,
		},
		id = id,
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})

	-- Click handler
	button:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			awful.spawn(command)
		end
	end)

	-- Hover effects
	button:connect_signal('mouse::enter', function()
		button.bg = palette.surface1.hex
	end)

	-- Restore the button background when the pointer leaves.
	button:connect_signal('mouse::leave', function()
		button.bg = palette.surface0.hex
	end)

	return button
end

--- Creates the previous, play-pause and next row.
-- @return wibox.widget The media controls row.
local function create_media_controls()
	return wibox.widget({
		create_media_button('previous', '󰒮', { 'playerctl', 'previous' }),
		create_media_button('play_pause', '󰐎', { 'playerctl', 'play-pause' }),
		create_media_button('next', '󰒭', { 'playerctl', 'next' }),
		layout = wibox.layout.flex.horizontal,
		spacing = 8,
	})
end

--- Creates the slider shared by the volume and brightness rows.
-- @param maximum number Highest value of the slider.
-- @return wibox.widget The slider.
local function create_styled_slider(maximum)
	return wibox.widget({
		widget = wibox.widget.slider,
		bar_shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, 25)
		end,
		bar_height = 25,
		bar_color = palette.surface0.hex,
		bar_active_color = palette.blue.hex,
		handle_shape = gears.shape.circle,
		handle_color = palette.blue.hex,
		handle_width = 25,
		handle_border_width = 1,
		handle_border_color = palette.blue.hex,
		minimum = 0,
		maximum = maximum,
		value = 69,
	})
end

--- Creates the icon button shown on the left of a slider row.
-- @param glyph string Icon glyph to draw.
-- @return wibox.widget The background wrapper, its bg reacts to the pointer.
-- @return wibox.widget The glyph label.
local function create_slider_icon(glyph)
	local icon = wibox.widget({
		{
			{
				id = 'icon_text',
				text = glyph,
				font = 'Symbols Nerd Font 16',
				halign = 'center',
				widget = wibox.widget.textbox,
			},
			widget = wibox.container.margin,
			margins = 10,
		},
		id = 'icon_bg',
		bg = palette.surface0.hex,
		shape = gears.shape.rounded_rect,
		widget = wibox.container.background,
	})

	return icon, icon:get_children_by_id('icon_text')[1]
end

--- Creates the volume slider with its mute icon and the one second volume poll.
-- @return wibox.widget The volume row.
local function create_volume_control()
	local is_muted = false
	local current_volume = 0

	local volume_slider = create_styled_slider(150)

	local volume_icon, icon_widget = create_slider_icon('󰕾')

	--- Picks the volume icon for the given level and mute state.
	-- @param volume number Volume in percent.
	local function update_volume_icon(volume)
		if is_muted or volume == 0 then
			icon_widget.text = '󰖁'
		elseif volume < 30 then
			icon_widget.text = ''
		elseif volume < 70 then
			icon_widget.text = '󰖀'
		else
			icon_widget.text = '󰕾'
		end
	end

	--- Reads wpctl and syncs the slider, the icon and the local mute state.
	local update_volume_slider = function()
		local volume
		local muted = false

		awful.spawn.with_line_callback({ 'wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@' }, {
			stdout = function(line)
				local vol_str = line:match('Volume: ([%d%.]+)')
				if vol_str then
					volume = math.floor(tonumber(vol_str) * 100)
				end
				if line:find('%[MUTED%]') then
					muted = true
				end
			end,
			output_done = function()
				if volume then
					current_volume = volume
					volume_slider.value = volume
				end
				is_muted = muted
				update_volume_icon(current_volume)
			end,
		})
	end

	poller.every(1, update_volume_slider)

	-- Set volume using wpctl
	volume_slider:connect_signal('property::value', function(_, new_value)
		local volume_level = math.floor(new_value)
		awful.spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', volume_level .. '%' })
		current_volume = volume_level
		update_volume_icon(volume_level)
	end)

	-- Toggle mute function
	--- Toggles the sink mute state and refreshes the icon.
	local function toggle_mute()
		awful.spawn.easy_async({ 'wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle' }, function()
			is_muted = not is_muted
			update_volume_icon(current_volume)
		end)
	end

	-- Hover effects
	volume_icon:connect_signal('mouse::enter', function()
		volume_icon:get_children_by_id('icon_bg')[1].bg = palette.surface1.hex
	end)

	-- Restore the icon background when the pointer leaves.
	volume_icon:connect_signal('mouse::leave', function()
		volume_icon:get_children_by_id('icon_bg')[1].bg = palette.surface0.hex
	end)

	-- Click to toggle mute
	volume_icon:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			toggle_mute()
		end
	end)

	local volume_container = wibox.widget({
		volume_icon,
		{
			volume_slider,
			widget = wibox.container.margin,
			margins = 10,
		},
		layout = wibox.layout.fixed.horizontal,
		forced_height = 50,
	})

	return volume_container
end

--- Creates the brightness slider with its icon and the one second brightness poll.
-- @return wibox.widget The brightness row.
local function create_brightness_control()
	local brightness_slider = create_styled_slider(95)

	local brightness_icon, icon_widget = create_slider_icon('󰃚')

	--- Picks the brightness icon for the given level.
	-- @param brightness number Brightness in percent.
	local function update_brightness_icon(brightness)
		if brightness == 0 then
			icon_widget.text = '󰃛'
		elseif brightness < 30 then
			icon_widget.text = '󰃞'
		elseif brightness < 70 then
			icon_widget.text = '󰃠'
		else
			icon_widget.text = '󰃚'
		end
	end

	--- Reads brightnessctl and syncs the slider and the icon.
	local update_brightness_slider = function()
		local brightness

		awful.spawn.with_line_callback({ 'brightnessctl', 'g' }, {
			stdout = function(line)
				brightness = tonumber(line:match('(%d+)'))
			end,
			output_done = function()
				if not brightness then
					return
				end

				local max_brightness

				awful.spawn.with_line_callback({ 'brightnessctl', 'm' }, {
					stdout = function(line)
						max_brightness = tonumber(line:match('(%d+)'))
					end,
					output_done = function()
						if not max_brightness then
							max_brightness = 65535
						end
						local real_brightness = math.floor((brightness / max_brightness) * 100)
						brightness_slider.value = real_brightness
						update_brightness_icon(real_brightness)
					end,
				})
			end,
		})
	end

	poller.every(1, update_brightness_slider)

	-- Set brightness using brightnessctl
	brightness_slider:connect_signal('property::value', function(_, new_value)
		local brightness_level = math.floor(new_value)
		awful.spawn({ 'brightnessctl', 'set', brightness_level .. '%' })
		update_brightness_icon(brightness_level)
	end)

	local brightness_container = wibox.widget({
		brightness_icon,
		{
			brightness_slider,
			widget = wibox.container.margin,
			margins = 10,
		},
		layout = wibox.layout.fixed.horizontal,
		forced_height = 50,
	})

	return brightness_container
end

--- Creates one round power button.
-- @param icon string Icon glyph to draw.
-- @param cmd string|table Command run on left click.
-- @return wibox.widget The round button.
local function create_round_button(icon, cmd)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = 'Symbols Nerd Font 35',
				halign = 'center',
				valign = 'center',
				widget = wibox.widget.textbox,
			},
			widget = wibox.container.margin,
			margins = 15,
		},
		id = 'button_bg',
		bg = palette.surface0.hex,
		shape = gears.shape.circle,
		widget = wibox.container.background,
		forced_width = 90,
		forced_height = 90,
	})

	-- Highlight the button while the pointer is on it.
	button:connect_signal('mouse::enter', function()
		button:get_children_by_id('button_bg')[1].bg = palette.surface1.hex
	end)

	-- Restore the button background when the pointer leaves.
	button:connect_signal('mouse::leave', function()
		button:get_children_by_id('button_bg')[1].bg = palette.surface0.hex
	end)

	-- Left click runs the button command.
	button:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			awful.spawn(cmd)
		end
	end)

	return button
end

--- Creates the grid of lock, logout, suspend, reboot and shutdown buttons.
-- @return wibox.widget The power grid.
local function create_power_grid()
	local grid_content = wibox.widget({
		layout = wibox.layout.grid,
		spacing = 10,
		forced_num_cols = 3,
	})

	local btn_lists = {
		create_round_button('', { os.getenv('HOME') .. '/.config/awesome/lock.sh' }),
		create_round_button(''),
		create_round_button('󰒲', { 'systemctl', '--no-ask-password', 'suspend' }),
		create_round_button(
			'󰍃',
			{ 'loginctl', '--no-ask-password', 'kill-user', os.getenv('USER'), '--signal=SIGKILL' }
		),
		create_round_button('󰜉', { 'systemctl', '--no-ask-password', 'reboot' }),
		create_round_button('', { 'systemctl', '--no-ask-password', 'poweroff' }),
	}

	for _, btn in ipairs(btn_lists) do
		grid_content:add(btn)
	end

	return grid_content
end

--- Builds the dashboard wibox on the primary screen; does nothing when it already exists.
function dashboard.create()
	if dashboard_wibox then
		return
	end

	dashboard_wibox = wibox({
		screen = screen.primary,
		width = 600,
		height = screen.primary.geometry.height - 30,
		x = screen.primary.geometry.width - 600,
		y = 30,
		ontop = true,
		visible = false,
		bg = palette.base.hex,
		type = 'dock',
		shape = gears.shape.rounded_rect,
	})

	dashboard_wibox:setup({
		{
			{
				{
					create_info_rows(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_launcher_grid(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_current_playing(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_media_controls(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_volume_control(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_brightness_control(),
					halign = 'center',
					widget = wibox.container.place,
				},
				{
					create_power_grid(),
					halign = 'center',
					widget = wibox.container.place,
				},
				spacing = 10,
				layout = wibox.layout.fixed.vertical,
			},
			margins = 20,
			widget = wibox.container.margin,
		},
		valign = 'top',
		widget = wibox.container.place,
	})

	dashboard_visible = false
end

--- Shows the dashboard when hidden, hides it otherwise.
function dashboard.toggle()
	if dashboard_visible then
		dashboard.hide()
	else
		dashboard.show()
	end
end

--- Makes the dashboard visible.
function dashboard.show()
	if dashboard_wibox then
		dashboard_wibox.visible = true
		dashboard_visible = true
	end
end

--- Hides the dashboard.
function dashboard.hide()
	if dashboard_wibox then
		dashboard_wibox.visible = false
		dashboard_visible = false
	end
end

return dashboard
