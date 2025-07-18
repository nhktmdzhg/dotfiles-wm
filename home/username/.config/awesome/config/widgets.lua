local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local timer = require("gears.timer")
local scripts = require("scripts")
local palette = require("mocha")
local client = require("client")

local widgets = {}

function widgets.create_tasklist(s)
    local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {
                raise = true
            })
        end
    end))

    local mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            shape_border_width = 1,
            shape_border_color = palette.sapphire.hex,
            shape = gears.shape.rounded_rect
        },
        layout = {
            spacing = 4,
            layout = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    id = "icon_role",
                    widget = wibox.widget.imagebox,
                    forced_width = 24
                },
                margins = 3,
                widget = wibox.container.margin
            },
            id = 'background_role',
            widget = wibox.container.background
        }
    }

    return wibox.container.constraint(mytasklist, "exact", nil, 32)
end

function widgets.create_arch_logo()
    local arch_logo = wibox.widget {
        {
            {
                markup = "",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
                font = "Iosevka 18"
            },
            margins = 2,
            widget = wibox.container.margin
        },
        widget = wibox.container.background,
        bg = "#f9f9f9ee",
        fg = "#434c5eff"
    }

    awful.tooltip {
        objects = { arch_logo },
        text = "[L] Main Menu [R] Power Menu",
        mode = "outside"
    }

    arch_logo:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn({ "env", "XMODIFIERS=@im=none", "rofi", "-no-lazy-grab", "-show", "drun" })
        elseif button == 3 then
            awful.spawn("wlogout")
        end
    end)

    arch_logo:connect_signal("mouse::enter", function()
        arch_logo.bg = "#f9f9f9cc"
    end)

    arch_logo:connect_signal("mouse::leave", function()
        arch_logo.bg = "#f9f9f9ee"
    end)

    return arch_logo
end

function widgets.create_systray()
    local mysystray = wibox.widget {
        wibox.widget.systray(),
        left = 10,
        right = 10,
        top = 2,
        bottom = 2,
        widget = wibox.container.margin
    }

    mysystray = wibox.container.background(mysystray)
    mysystray.bg = palette.surface0.hex
    mysystray.shape = gears.shape.rounded_bar
    mysystray.shape_clip = true

    return mysystray
end

function widgets.create_window_name(s)
    local window_name = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local window_name_container = wibox.container.margin(window_name, 5, 5, 0, 0)
    window_name_container = wibox.container.background(window_name_container)
    window_name_container.bg = palette.surface0.hex
    window_name_container.fg = palette.text.hex
    window_name_container.shape = gears.shape.rounded_bar
    window_name_container.shape_clip = true

    awful.tooltip {
        objects = { window_name_container },
        text = "Window Name",
        mode = "outside"
    }

    timer {
        timeout = 0.1,
        autostart = true,
        callnow = true,
        callback = function()
            local c = client.focus
            local name = ""
            if c then
                name = c.name
            else
                name = "No focused window"
                s.mywibox.visible = true
                awful.spawn({ "dunstctl", "set-paused", "false" })
            end
            local length = string.len(name)
            if length < 60 then
                window_name.text = name
            else
                local unix_time = os.time()
                local i = unix_time % (length - 58)
                window_name.text = string.sub(name, i, i + 59)
            end
        end
    }

    return window_name_container
end

function widgets.create_battery()
    local battery_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font = "MesloLGS Nerd Font Mono 14",
        align = "center",
        valign = "center"
    }

    local battery_icon_container = wibox.container.margin(battery_icon, 5, 5, 0, 0)
    battery_icon_container = wibox.container.background(battery_icon_container)
    battery_icon_container.bg = palette.text.hex
    battery_icon_container.fg = palette.surface0.hex
    battery_icon_container.shape = gears.shape.circle
    battery_icon_container.shape_clip = true

    awful.tooltip {
        objects = { battery_icon_container },
        text = "Battery Status",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_battery_icon(function(icon)
                battery_icon.text = icon
            end)
        end
    }

    local battery_percent = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local battery_percent_container = wibox.container.margin(battery_percent, 5, 5, 0, 0)
    battery_percent_container = wibox.container.background(battery_percent_container)
    battery_percent_container.bg = palette.surface0.hex
    battery_percent_container.fg = palette.text.hex
    battery_percent_container.shape = gears.shape.rounded_bar
    battery_percent_container.shape_clip = true

    awful.tooltip {
        objects = { battery_percent_container },
        text = "Battery percent",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_battery_percent(function(percent)
                if percent then
                    battery_percent.text = percent .. " %"
                else
                    battery_percent.text = "N/A"
                end
            end)
        end
    }

    return battery_icon_container, battery_percent_container
end

function widgets.create_network()
    local network_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Material Bold 10",
        align = "center",
        valign = "center"
    }

    local network_icon_container = wibox.container.margin(network_icon, 5, 5, 0, 0)
    network_icon_container = wibox.container.background(network_icon_container)
    network_icon_container.bg = palette.text.hex
    network_icon_container.fg = palette.surface0.hex
    network_icon_container.shape = gears.shape.circle
    network_icon_container.shape_clip = true

    awful.tooltip {
        objects = { network_icon_container },
        text = "Network Status",
        mode = "outside"
    }

    network_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn({ "wezterm", "-e", "nmcurse" })
        end
    end)

    network_icon_container:connect_signal("mouse::enter", function()
        network_icon_container.bg = palette.text.hex .. "cc"
    end)

    network_icon_container:connect_signal("mouse::leave", function()
        network_icon_container.bg = palette.text.hex
    end)

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_network_info(0, function(icon)
                network_icon.text = icon
            end)
        end
    }

    local network_status = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local network_status_container = wibox.container.margin(network_status, 5, 5, 0, 0)
    network_status_container = wibox.container.background(network_status_container)
    network_status_container.bg = palette.surface0.hex
    network_status_container.fg = palette.text.hex
    network_status_container.shape = gears.shape.rounded_bar
    network_status_container.shape_clip = true

    awful.tooltip {
        objects = { network_status_container },
        text = "SSID",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_network_info(1, function(status)
                network_status.text = status
            end)
        end
    }

    return network_icon_container, network_status_container
end

function widgets.create_volume()
    local volume_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Material Bold 10",
        align = "center",
        valign = "center"
    }

    local volume_icon_container = wibox.container.margin(volume_icon, 5, 5, 0, 0)
    volume_icon_container = wibox.container.background(volume_icon_container)
    volume_icon_container.bg = palette.text.hex
    volume_icon_container.fg = palette.surface0.hex
    volume_icon_container.shape = gears.shape.circle
    volume_icon_container.shape_clip = true

    awful.tooltip {
        objects = { volume_icon_container },
        text = "[L] Toggle Audio Mute [S] Audio Volume +/-",
        mode = "outside"
    }

    timer {
        timeout = 0.1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_volume_info(2, function(icon)
                volume_icon.text = icon
            end)
        end
    }

    volume_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            scripts.get_volume_info(0, nil)
        elseif button == 4 then
            scripts.get_volume_info(1, nil)
        elseif button == 5 then
            scripts.get_volume_info(-1, nil)
        end
    end)

    volume_icon_container:connect_signal("mouse::enter", function()
        volume_icon_container.bg = palette.text.hex .. "cc"
    end)

    volume_icon_container:connect_signal("mouse::leave", function()
        volume_icon_container.bg = palette.text.hex
    end)

    local volume_percent = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local volume_percent_container = wibox.container.margin(volume_percent, 5, 5, 0, 0)
    volume_percent_container = wibox.container.background(volume_percent_container)
    volume_percent_container.bg = palette.surface0.hex
    volume_percent_container.fg = palette.text.hex
    volume_percent_container.shape = gears.shape.rounded_bar
    volume_percent_container.shape_clip = true

    awful.tooltip {
        objects = { volume_percent_container },
        text = "[S] Audio Volume +/-",
        mode = "outside"
    }

    timer {
        timeout = 0.1,
        autostart = true,
        callnow = true,
        callback = function()
            scripts.get_volume_info(3, function(status)
                volume_percent.text = status or "N/A"
            end)
        end
    }

    volume_percent_container:connect_signal("button::press", function(_, _, _, button)
        if button == 4 then
            scripts.get_volume_info(1, nil)
        elseif button == 5 then
            scripts.get_volume_info(-1, nil)
        end
    end)

    return volume_icon_container, volume_percent_container
end

function widgets.create_calendar()
    local calendar_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Material Bold 10",
        align = "center",
        valign = "center",
        text = ""
    }

    local calendar_icon_container = wibox.container.margin(calendar_icon, 5, 5, 0, 0)
    calendar_icon_container = wibox.container.background(calendar_icon_container)
    calendar_icon_container.bg = palette.text.hex
    calendar_icon_container.fg = palette.surface0.hex
    calendar_icon_container.shape = gears.shape.circle
    calendar_icon_container.shape_clip = true

    awful.tooltip {
        objects = { calendar_icon_container },
        text = "Calendar",
        mode = "outside"
    }

    calendar_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn("gsimplecal")
        end
    end)

    calendar_icon_container:connect_signal("mouse::enter", function()
        calendar_icon_container.bg = palette.text.hex .. "cc"
    end)

    calendar_icon_container:connect_signal("mouse::leave", function()
        calendar_icon_container.bg = palette.text.hex
    end)

    local date_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local date_widget_container = wibox.container.margin(date_widget, 5, 5, 0, 0)
    date_widget_container = wibox.container.background(date_widget_container)
    date_widget_container.bg = palette.surface0.hex
    date_widget_container.fg = palette.text.hex
    date_widget_container.shape = gears.shape.rounded_bar
    date_widget_container.shape_clip = true

    awful.tooltip {
        objects = { date_widget_container },
        text = "Date",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            awful.spawn.easy_async({ "date", "+%Y年%m月%d日" }, function(stdout)
                date_widget.text = stdout:gsub("%s+$", "")
            end)
        end
    }

    local time_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono 9",
        align = "center",
        valign = "center"
    }

    local time_widget_container = wibox.container.margin(time_widget, 5, 5, 0, 0)
    time_widget_container = wibox.container.background(time_widget_container)
    time_widget_container.bg = palette.surface0.hex
    time_widget_container.fg = palette.text.hex
    time_widget_container.shape = gears.shape.rounded_bar
    time_widget_container.shape_clip = true

    awful.tooltip {
        objects = { time_widget_container },
        text = "Time",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            awful.spawn.easy_async({ "date", "+%H:%M:%S %p" }, function(stdout)
                time_widget.text = stdout:gsub("%s+$", "")
            end)
        end
    }

    return calendar_icon_container, date_widget_container, time_widget_container
end

function widgets.create_separators()
    local sep_left = wibox.widget {
        markup = "",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Iosevka 14"
    }

    local sep_right = wibox.widget {
        markup = '',
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Iosevka 14"
    }

    local seperator = wibox.widget {
        widget = wibox.widget.separator,
        orientation = "vertical",
        forced_width = 6,
        color = "#00000000"
    }

    return sep_left, sep_right, seperator
end

return widgets
