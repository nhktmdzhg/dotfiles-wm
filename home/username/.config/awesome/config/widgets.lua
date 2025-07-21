local table = require("gears.table")
local timer = require("gears.timer")

local wibox = require("wibox")

local button = require("awful.button")
local widget = require("awful.widget")
local tooltip = require("awful.tooltip")
local spawn = require("awful.spawn")

local scripts = require("scripts")
local palette = require("mocha")
local client = require("client")
local filesystem = require("gears.filesystem")
local surface = require("gears.surface")

-- Path to default icon
local noicon_path = filesystem.get_configuration_dir() .. "awesome-switcher/noicon.png"

local widgets = {}

function widgets.create_tasklist(s)
    local tasklist_buttons = table.join(button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {
                raise = true
            })
        end
    end))

    local mytasklist = widget.tasklist {
        screen = s,
        filter = widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            bg_normal = palette.base.hex,
            bg_focus = palette.surface0.hex,
            fg_normal = palette.text.hex,
            fg_focus = palette.text.hex
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
            widget = wibox.container.background,
            create_callback = function(self, c, _, _)
                -- Set icon when widget is created
                local icon_widget = self:get_children_by_id('icon_role')[1]
                if icon_widget then
                    if c and c.icon then
                        icon_widget.image = c.icon
                    else
                        icon_widget.image = surface.load_uncached(noicon_path)
                    end
                end
            end,
            update_callback = function(self, c, _, _)
                -- Update icon when client changes
                local icon_widget = self:get_children_by_id('icon_role')[1]
                if icon_widget then
                    if c and c.icon then
                        icon_widget.image = c.icon
                    else
                        icon_widget.image = surface.load_uncached(noicon_path)
                    end
                end
            end
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
            margins = 8,
            widget = wibox.container.margin
        },
        widget = wibox.container.background,
        bg = palette.base.hex,
        fg = palette.mauve.hex
    }

    tooltip {
        objects = { arch_logo },
        text = "[L] Main Menu [R] Power Menu",
        mode = "outside"
    }

    arch_logo:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            spawn({ "env", "XMODIFIERS=@im=none", "rofi", "-no-lazy-grab", "-show", "drun" })
        elseif button == 3 then
            spawn("wlogout")
        end
    end)

    arch_logo:connect_signal("mouse::enter", function()
        arch_logo.fg = palette.pink.hex
    end)

    arch_logo:connect_signal("mouse::leave", function()
        arch_logo.fg = palette.mauve.hex
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
    mysystray.bg = palette.base.hex

    return mysystray
end

function widgets.create_window_name(s)
    local window_name = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local window_name_container = wibox.container.margin(window_name, 8, 8, 6, 6)
    window_name_container = wibox.container.background(window_name_container)
    window_name_container.bg = palette.base.hex
    window_name_container.fg = palette.text.hex

    tooltip {
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
                s.mywibar.visible = true
                spawn({ "dunstctl", "set-paused", "false" })
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

    local battery_icon_container = wibox.container.margin(battery_icon, 8, 8, 6, 6)
    battery_icon_container = wibox.container.background(battery_icon_container)
    battery_icon_container.bg = palette.base.hex
    battery_icon_container.fg = palette.green.hex

    tooltip {
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

    local battery_percent_container = wibox.container.margin(battery_percent, 8, 8, 6, 6)
    battery_percent_container = wibox.container.background(battery_percent_container)
    battery_percent_container.bg = palette.base.hex
    battery_percent_container.fg = palette.text.hex

    tooltip {
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

    local network_icon_container = wibox.container.margin(network_icon, 8, 8, 6, 6)
    network_icon_container = wibox.container.background(network_icon_container)
    network_icon_container.bg = palette.base.hex
    network_icon_container.fg = palette.blue.hex

    tooltip {
        objects = { network_icon_container },
        text = "Network Status",
        mode = "outside"
    }

    network_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            spawn({ "wezterm", "-e", "nmcurse" })
        end
    end)

    network_icon_container:connect_signal("mouse::enter", function()
        network_icon_container.fg = palette.sky.hex
    end)

    network_icon_container:connect_signal("mouse::leave", function()
        network_icon_container.fg = palette.blue.hex
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

    local network_status_container = wibox.container.margin(network_status, 8, 8, 6, 6)
    network_status_container = wibox.container.background(network_status_container)
    network_status_container.bg = palette.base.hex
    network_status_container.fg = palette.text.hex

    tooltip {
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

    local volume_icon_container = wibox.container.margin(volume_icon, 8, 8, 6, 6)
    volume_icon_container = wibox.container.background(volume_icon_container)
    volume_icon_container.bg = palette.base.hex
    volume_icon_container.fg = palette.peach.hex

    tooltip {
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
        volume_icon_container.fg = palette.yellow.hex
    end)

    volume_icon_container:connect_signal("mouse::leave", function()
        volume_icon_container.fg = palette.peach.hex
    end)

    local volume_percent = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local volume_percent_container = wibox.container.margin(volume_percent, 8, 8, 6, 6)
    volume_percent_container = wibox.container.background(volume_percent_container)
    volume_percent_container.bg = palette.base.hex
    volume_percent_container.fg = palette.text.hex

    tooltip {
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

    local calendar_icon_container = wibox.container.margin(calendar_icon, 8, 8, 6, 6)
    calendar_icon_container = wibox.container.background(calendar_icon_container)
    calendar_icon_container.bg = palette.base.hex
    calendar_icon_container.fg = palette.red.hex

    tooltip {
        objects = { calendar_icon_container },
        text = "Calendar",
        mode = "outside"
    }

    calendar_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            spawn("gsimplecal")
        end
    end)

    calendar_icon_container:connect_signal("mouse::enter", function()
        calendar_icon_container.fg = palette.maroon.hex
    end)

    calendar_icon_container:connect_signal("mouse::leave", function()
        calendar_icon_container.fg = palette.red.hex
    end)

    local date_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 9",
        align = "center",
        valign = "center"
    }

    local date_widget_container = wibox.container.margin(date_widget, 8, 8, 6, 6)
    date_widget_container = wibox.container.background(date_widget_container)
    date_widget_container.bg = palette.base.hex
    date_widget_container.fg = palette.text.hex

    tooltip {
        objects = { date_widget_container },
        text = "Date",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            spawn.easy_async({ "date", "+%Y年%m月%d日" }, function(stdout)
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

    local time_widget_container = wibox.container.margin(time_widget, 8, 8, 6, 6)
    time_widget_container = wibox.container.background(time_widget_container)
    time_widget_container.bg = palette.base.hex
    time_widget_container.fg = palette.text.hex

    tooltip {
        objects = { time_widget_container },
        text = "Time",
        mode = "outside"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            spawn.easy_async({ "date", "+%H:%M:%S %p" }, function(stdout)
                time_widget.text = stdout:gsub("%s+$", "")
            end)
        end
    }

    return calendar_icon_container, date_widget_container, time_widget_container
end

function widgets.create_simple_separator()
    local separator = wibox.widget {
        markup = "|",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Kurinto Mono JP 15",
    }

    local separator_container = wibox.container.background(separator)
    separator_container.bg = palette.base.hex
    separator_container.fg = palette.overlay0.hex

    return separator_container
end

return widgets
