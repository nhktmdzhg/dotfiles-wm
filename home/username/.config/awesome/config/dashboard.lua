---@diagnostic disable: undefined-global
local awful = require('awful')
local gears = require('gears')
local palette = require('mocha')
local wibox = require('wibox')

local dashboard = {}

local dashboard_wibox = nil
local dashboard_visible = false

local avatar_path = os.getenv('HOME') .. '/.config/awesome/avatar.png'
local launcher_list = {
	{ name = 'St', icon = '', command = 'st' },
	{ name = 'Zen browser', icon = '󰺕', command = 'zen-browser' },
	{ name = 'PCManFM', icon = '', command = 'pcmanfm-qt' },
	{ name = 'Neovim', icon = '', command = 'goneovim' },
	{ name = 'Open config', icon = '', command = { 'sh', '-c', 'cd ~/.config/awesome && goneovim rc.lua' } },
	{
		name = 'HSR',
		icon = '',
		command = { 'env', 'MANGOHUD=1', 'XMODIFIERS=@im=none', 'bottles-cli', 'run', '-p', 'HSR', '-b', 'michos' },
	},
}

local function create_avatar_widget()
	return wibox.widget({
		{
			image = avatar_path,
			resize = true,
			forced_height = 100,
			forced_width = 100,
			widget = wibox.widget.imagebox,
		},
		margins = 20,
		widget = wibox.container.margin,
	})
end

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

local function create_launcher_widget(launcher)
	local launcher_widget = wibox.widget({
		{
			text = launcher.icon,
			font = 'JetBrainsMono Nerd Font Mono 14',
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
	launcher_container:connect_signal('button::press', function(_, _, _, button)
		if button == 1 then
			awful.spawn(launcher.command)
		end
	end)

	launcher_container:connect_signal('mouse::enter', function()
		launcher_container.bg = palette.surface1.hex
	end)

	launcher_container:connect_signal('mouse::leave', function()
		launcher_container.bg = palette.surface0.hex
	end)

	return launcher_container
end

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

local function create_current_playing()
	local current_widget = wibox.widget({
		{
			font = 'Maple Mono NF CN 12',
			widget = wibox.widget.textbox,
			halign = 'center',
		},
		fg = palette.text.hex,
		widget = wibox.container.background,
	})

	local scroll_container = wibox.container.scroll.horizontal(current_widget, 2, 50, 0)

	scroll_container:set_max_size(400)
	scroll_container:set_step_function(wibox.container.scroll.step_functions.linear_back_and_forth)

	gears.timer({
		timeout = 1,
		autostart = true,
		call_now = true,
		callback = function()
			awful.spawn.easy_async(
				{ 'playerctl', 'metadata', '--format', '{{ title }} - {{ artist }}' },
				function(stdout)
					local current_song = stdout:gsub('%s+$', '')
					if current_song == '' then
						current_song = 'No song playing'
					else
						current_song = 'Now Playing: ' .. current_song
					end
					current_widget.widget.text = current_song
				end
			)
		end,
	})

	return scroll_container
end

local function create_media_button(id, icon, command)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = 'JetBrainsMono Nerd Font Mono 16',
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
	button:connect_signal('button::press', function(_, _, _, btn)
		if btn == 1 then
			awful.spawn(command)
		end
	end)

	-- Hover effects
	button:connect_signal('mouse::enter', function()
		button.bg = palette.surface1.hex
	end)

	button:connect_signal('mouse::leave', function()
		button.bg = palette.surface0.hex
	end)

	return button
end

local function create_media_controls()
	return wibox.widget({
		create_media_button('previous', '󰒮', { 'playerctl', 'previous' }),
		create_media_button('play_pause', '󰐎', { 'playerctl', 'play-pause' }),
		create_media_button('next', '󰒭', { 'playerctl', 'next' }),
		layout = wibox.layout.flex.horizontal,
		spacing = 8,
	})
end

local function create_volume_control()
	local is_muted = false
	local current_volume = 0

	local volume_slider = wibox.widget({
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
		maximum = 150,
		value = 69,
	})

	local volume_icon = wibox.widget({
		{
			{
				id = 'icon_text',
				text = '󰕾',
				font = 'JetBrainsMono Nerd Font Mono 16',
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

	local function update_volume_icon(volume)
		local icon_widget = volume_icon:get_children_by_id('icon_text')[1]
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

	local update_volume_slider = function()
		awful.spawn.easy_async({ 'wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@' }, function(stdout)
			local vol_str = stdout:match('Volume: ([%d%.]+)')
			if vol_str then
				local volume = math.floor(tonumber(vol_str) * 100)
				current_volume = volume
				volume_slider.value = volume
				update_volume_icon(volume)
			end
			is_muted = stdout:find('%[MUTED%]') ~= nil
			update_volume_icon(current_volume)
		end)
	end

	gears.timer({
		timeout = 1,
		call_now = true,
		autostart = true,
		callback = update_volume_slider,
	})

	-- Set volume using wpctl
	volume_slider:connect_signal('property::value', function(slider)
		local volume_level = math.floor(slider.value)
		awful.spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', volume_level .. '%' })
		current_volume = volume_level
		update_volume_icon(volume_level)
	end)

	-- Toggle mute function
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

local function create_brightness_control()
	local brightness_slider = wibox.widget({
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
		maximum = 100,
		value = 69,
	})

	local brightness_icon = wibox.widget({
		{
			{
				id = 'icon_text',
				text = '󰃚',
				font = 'JetBrainsMono Nerd Font Mono 16',
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

	local function update_brightness_icon(brightness)
		local icon_widget = brightness_icon:get_children_by_id('icon_text')[1]
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

	local update_brightness_slider = function()
		awful.spawn.easy_async({ 'brightnessctl', 'g' }, function(stdout)
			local brightness = tonumber(stdout:match('(%d+)'))
			if brightness then
				brightness_slider.value = brightness
				update_brightness_icon(brightness)
			end
		end)
	end

	gears.timer({
		timeout = 1,
		call_now = true,
		autostart = true,
		callback = update_brightness_slider,
	})

	-- Set brightness using brightnessctl
	brightness_slider:connect_signal('property::value', function(slider)
		local brightness_level = math.floor(slider.value)
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

local function create_round_button(icon, cmd)
	local button = wibox.widget({
		{
			{
				text = icon,
				font = 'JetBrainsMono Nerd Font Mono 50',
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

	button:connect_signal('mouse::enter', function()
		button:get_children_by_id('button_bg')[1].bg = palette.surface1.hex
	end)

	button:connect_signal('mouse::leave', function()
		button:get_children_by_id('button_bg')[1].bg = palette.surface0.hex
	end)

	button:connect_signal('button::press', function(_, _, _, btn)
		if btn == 1 then
			awful.spawn(cmd)
		end
	end)

	return button
end

local function create_power_grid()
	local grid_content = wibox.widget({
		layout = wibox.layout.grid,
		spacing = 10,
		forced_num_cols = 3,
	})

	local btn_lists = {
		create_round_button('', os.getenv('HOME') .. '/.config/awesome/lock.sh'),
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

function dashboard.toggle()
	if dashboard_visible then
		dashboard.hide()
	else
		dashboard.show()
	end
end

function dashboard.show()
	if dashboard_wibox then
		dashboard_wibox.visible = true
		dashboard_visible = true
	end
end

function dashboard.hide()
	if dashboard_wibox then
		dashboard_wibox.visible = false
		dashboard_visible = false
	end
end

return dashboard
