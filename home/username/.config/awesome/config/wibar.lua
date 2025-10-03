---@diagnostic disable: undefined-global
local awful_screen = require('awful.screen')
local awful_wibar = require('awful.wibar')
local dashboard = require('config.dashboard')
local layout = require('awful.layout')
local palette = require('mocha')
local tag = require('awful.tag')
local wallpaper = require('gears.wallpaper')
local wibox = require('wibox')
local widgets = require('config.widgets')

local wibar = {}

local function set_wallpaper(s, vars)
	wallpaper.maximized(vars.wallpaper, s, true)
end

function wibar.init(vars)
	-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
	screen.connect_signal('property::geometry', function(s)
		set_wallpaper(s, vars)
	end)

	awful_screen.connect_for_each_screen(function(s)
		-- Wallpaper
		set_wallpaper(s, vars)

		-- Each screen has its own tag table.
		tag({ '1' }, s, layout.layouts[1])

		-- Create the wibar
		s.mywibar = awful_wibar({
			position = 'top',
			screen = s,
			height = 30,
			bg = palette.base.hex,
			fg = palette.text.hex,
			ontop = true,
			visible = true,
		})

		-- Create widgets
		local constrained_tasklist = widgets.create_tasklist(s)
		local simple_separator = widgets.create_simple_separator()
		local arch_logo = widgets.create_arch_logo()
		local mysystray = widgets.create_systray()
		local window_name_container = widgets.create_window_name(s)
		local battery_icon_container, battery_percent_container = widgets.create_battery()
		local network_icon_container, network_status_container = widgets.create_network()
		local volume_icon_container, volume_percent_container = widgets.create_volume()
		local calendar_icon_container, date_widget_container, time_widget_container = widgets.create_calendar()
		local dashboard_toggle_container = widgets.create_dashboard_toggle()
		dashboard.create()

		-- Add widgets to the wibar
		s.mywibar:setup({
			layout = wibox.layout.align.horizontal,
			{ -- Left widgets
				layout = wibox.layout.fixed.horizontal,
				simple_separator,
				arch_logo,
				simple_separator,
				mysystray,
			},
			{
				constrained_tasklist,
				halign = 'center',
				valign = 'center',
				widget = wibox.container.place,
			},
			{ -- Right widgets
				layout = wibox.layout.fixed.horizontal,
				window_name_container,
				simple_separator,
				battery_icon_container,
				simple_separator,
				battery_percent_container,
				simple_separator,
				network_icon_container,
				simple_separator,
				network_status_container,
				simple_separator,
				volume_icon_container,
				simple_separator,
				volume_percent_container,
				simple_separator,
				calendar_icon_container,
				simple_separator,
				date_widget_container,
				simple_separator,
				time_widget_container,
				simple_separator,
				dashboard_toggle_container,
				simple_separator,
			},
		})
	end)
end

return wibar
