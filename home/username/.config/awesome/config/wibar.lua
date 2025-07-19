local wallpaper = require("gears.wallpaper")
local awful_screen = require("awful.screen")
local tag = require("awful.tag")
local layout = require("awful.layout")
local wibox = require("wibox")
local screen = require("screen")
local widgets = require("config.widgets")

local wibar = {}

local function set_wallpaper(s, vars)
    wallpaper.maximized(vars.home .. "/wallpaper/march 7th 4k.jpg", s, true)
end

function wibar.init(vars)
    -- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
    screen.connect_signal("property::geometry", function(s)
        set_wallpaper(s, vars)
    end)

    awful_screen.connect_for_each_screen(function(s)
        -- Wallpaper
        set_wallpaper(s, vars)

        -- Each screen has its own tag table.
        tag({ "1" }, s, layout.layouts[1])

        -- Create the wibox
        s.mywibox = wibox({
            position = "top",
            screen = s,
            width = s.geometry.width - 10,
            height = vars.wibox_height,
            x = vars.wibox_margin,
            y = vars.wibox_margin,
            bg = "#00000000",
            fg = "#ffffff",
            ontop = true,
            visible = true
        })

        -- Create widgets
        local constrained_tasklist = widgets.create_tasklist(s)
        local sep_left, sep_right, seperator = widgets.create_separators()
        local arch_logo = widgets.create_arch_logo()
        local mysystray = widgets.create_systray()
        local window_name_container = widgets.create_window_name(s)
        local battery_icon_container, battery_percent_container = widgets.create_battery()
        local network_icon_container, network_status_container = widgets.create_network()
        local volume_icon_container, volume_percent_container = widgets.create_volume()
        local calendar_icon_container, date_widget_container, time_widget_container = widgets.create_calendar()

        -- Add widgets to the wibox
        s.mywibox:setup {
            layout = wibox.layout.align.horizontal,
            { -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                sep_left,
                arch_logo,
                sep_right,
                mysystray
            },
            {
                constrained_tasklist,
                halign = "center",
                valign = "center",
                widget = wibox.container.place
            },
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                window_name_container,
                seperator,
                battery_icon_container,
                seperator,
                battery_percent_container,
                seperator,
                network_icon_container,
                seperator,
                network_status_container,
                seperator,
                volume_icon_container,
                seperator,
                volume_percent_container,
                seperator,
                calendar_icon_container,
                seperator,
                date_widget_container,
                seperator,
                time_widget_container
            }
        }
    end)
end

return wibar
