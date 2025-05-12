local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local timer = require("gears.timer")
local scripts = require("scripts")
require("awful.hotkeys_popup.keys")

local super         = "Mod4"
local alt           = "Mod1"
local ctrl          = "Control"
local shift         = "Shift"
local margin_top    = 10
local margin_bottom = 10
local margin_left   = 10
local margin_right  = 10

if awesome.startup_errors then
    awesome.spawn("dunstify -u critical -t 'Oops, there were errors during startup!' -a 'AwesomeWM' -i 'arch-error' '" ..
        awesome.startup_errors .. "'")
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        awesome.spawn("dunstify -u critical -t 'Oops, an error happened!' -a 'AwesomeWM' -i 'arch-error' '" ..
            tostring(err) .. "'")
        in_error = false
    end)
end

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

awful.layout.layouts = {
    awful.layout.suit.floating
}

-- {{{ Wibar

local function get_output_of_cmd(cmd)
    local handle = io.popen(cmd)
    local result = handle and handle:read("*a") or ""
    if handle then
        handle:close()
    end
    return result
end

-- Create a wibox for each screen and add it
-- local taglist_buttons = gears.table.join(
--     awful.button({}, 1, function(t) t:view_only() end),
--     awful.button({ super }, 1, function(t)
--         if client.focus then
--             client.focus:move_to_tag(t)
--         end
--     end),
--     awful.button({}, 3, awful.tag.viewtoggle),
--     awful.button({ super }, 3, function(t)
--         if client.focus then
--             client.focus:toggle_tag(t)
--         end
--     end),
--     awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
--     awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
-- )

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                { raise = true }
            )
        end
    end)
)

local function set_wallpaper(s)
    local wallpaper_path = "/home/iamnanoka/wallpaper/march 7th 4k.jpg"
    gears.wallpaper.maximized(wallpaper_path, s, true)
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1" }, s, awful.layout.layouts[1])

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        width = s.geometry.width - 10,
        height = 30,
        x = 5,
        y = 5,
        bg = "#00000000",
        fg = "#ffffff",
        ontop = true
    })

    s.mytasklist = awful.widget.tasklist {
        screen          = s,
        filter          = awful.widget.tasklist.filter.currenttags,
        buttons         = tasklist_buttons,
        style           = {
            shape_border_width = 1,
            shape_border_color = '#777777',
            shape              = gears.shape.rounded_rect
        },
        layout          = {
            spacing = 4,
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    id           = "icon_role",
                    widget       = wibox.widget.imagebox,
                    forced_width = 28
                },
                margins = 2,
                widget  = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background
        }
    }

    local constrained_tasklist = wibox.container.constraint(s.mytasklist, "exact", nil, 32)

    -- Custom widgets
    local sep_left = wibox.widget {
        markup = "",
        align  = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font   = "Iosevka 14"
    }

    local arch_logo = wibox.widget {
        {
            {
                markup = "",
                align  = "center",
                valign = "center",
                widget = wibox.widget.textbox,
                font   = "Iosevka 18"
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
        text = "[L] Main Menu [R] Extensions Menu"
    }

    arch_logo:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn.with_shell(
                "XMODIFIERS=@im=none rofi -theme-str '@import \"main.rasi\"' -no-lazy-grab -show drun -modi drun")
        elseif button == 3 then
            awful.spawn.with_shell("~/.config/rofi/scripts/rofi-exts.sh")
        end
    end)

    arch_logo:connect_signal("mouse::enter", function()
        arch_logo.bg = "#f9f9f9cc"
    end)

    arch_logo:connect_signal("mouse::leave", function()
        arch_logo.bg = "#f9f9f9ee"
    end)

    local seperator = wibox.widget {
        widget = wibox.widget.separator,
        orientation = "vertical",
        forced_width = 6,
        color = "#00000000"
    }

    local sep_right = wibox.widget {
        markup = '',
        align  = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font   = "Iosevka 14"
    }

    local mysystray = wibox.widget {
        wibox.widget.systray(),
        left = 10,
        right = 10,
        top = 2,
        bottom = 2,
        widget = wibox.container.margin
    }

    mysystray = wibox.container.background(mysystray)
    mysystray.bg = "#434c5e"
    mysystray.shape = gears.shape.rounded_rect
    mysystray.shape_clip = true

    local window_name = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono JP 9",
        align  = "center",
        valign = "center"
    }

    local window_name_container = wibox.container.margin(window_name, 5, 5, 0, 0)
    window_name_container = wibox.container.background(window_name_container)
    window_name_container.bg = "#434c5eee"
    window_name_container.fg = "#f9f9f9ff"
    window_name_container.shape = gears.shape.rounded_bar
    window_name_container.shape_clip = true

    awful.tooltip {
        objects = { window_name_container },
        text = "Window Name"
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

    local battery_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "MesloLGS Nerd Font Mono 15",
        align  = "center",
        valign = "center"
    }

    local battery_icon_container = wibox.container.margin(battery_icon, 5, 5, 0, 0)
    battery_icon_container = wibox.container.background(battery_icon_container)
    battery_icon_container.bg = "#f9f9f9ee"
    battery_icon_container.fg = "#434c5eff"
    battery_icon_container.shape = gears.shape.circle
    battery_icon_container.shape_clip = true

    awful.tooltip {
        objects = { battery_icon_container },
        text = "Battery Status"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            battery_icon.text = scripts.get_battery_icon()
        end
    }

    local battery_percent = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono JP 9",
        align  = "center",
        valign = "center"
    }

    local battery_percent_container = wibox.container.margin(battery_percent, 5, 5, 0, 0)
    battery_percent_container = wibox.container.background(battery_percent_container)
    battery_percent_container.bg = "#434c5eee"
    battery_percent_container.fg = "#f9f9f9ff"
    battery_percent_container.shape = gears.shape.rounded_bar
    battery_percent_container.shape_clip = true

    awful.tooltip {
        objects = { battery_percent_container },
        text = "Battery percent"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            battery_percent.text = scripts.get_battery_percent() .. "%"
        end
    }

    local network_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Material Bold 10",
        align  = "center",
        valign = "center"
    }

    local network_icon_container = wibox.container.margin(network_icon, 5, 5, 0, 0)
    network_icon_container = wibox.container.background(network_icon_container)
    network_icon_container.bg = "#f9f9f9ee"
    network_icon_container.fg = "#434c5eff"
    network_icon_container.shape = gears.shape.circle
    network_icon_container.shape_clip = true

    awful.tooltip {
        objects = { network_icon_container },
        text = "Network Status"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            network_icon.text = scripts.get_network_info(0)
        end
    }

    local network_status = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono JP 9",
        align  = "center",
        valign = "center"
    }

    local network_status_container = wibox.container.margin(network_status, 5, 5, 0, 0)
    network_status_container = wibox.container.background(network_status_container)
    network_status_container.bg = "#434c5eee"
    network_status_container.fg = "#f9f9f9ff"
    network_status_container.shape = gears.shape.rounded_bar
    network_status_container.shape_clip = true

    awful.tooltip {
        objects = { network_status_container },
        text = "Network IP/SSID"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            network_status.text = scripts.get_network_info(1)
        end
    }

    local volume_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Material Bold 10",
        align  = "center",
        valign = "center"
    }

    local volume_icon_container = wibox.container.margin(volume_icon, 5, 5, 0, 0)
    volume_icon_container = wibox.container.background(volume_icon_container)
    volume_icon_container.bg = "#f9f9f9ee"
    volume_icon_container.fg = "#434c5eff"
    volume_icon_container.shape = gears.shape.circle
    volume_icon_container.shape_clip = true

    awful.tooltip {
        objects = { volume_icon_container },
        text = "[L] Toggle Audio Mute [S] Audio Volume +/-"
    }

    timer {
        timeout = 0.1,
        autostart = true,
        callnow = true,
        callback = function()
            volume_icon.text = scripts.get_volume_info(2)
        end
    }

    volume_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            scripts.get_volume_info(0)
        elseif button == 4 then
            scripts.get_volume_info(1)
        elseif button == 5 then
            scripts.get_volume_info(-1)
        end
    end)

    local volume_percent = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono JP 9",
        align  = "center",
        valign = "center"
    }

    local volume_percent_container = wibox.container.margin(volume_percent, 5, 5, 0, 0)
    volume_percent_container = wibox.container.background(volume_percent_container)
    volume_percent_container.bg = "#434c5eee"
    volume_percent_container.fg = "#f9f9f9ff"
    volume_percent_container.shape = gears.shape.rounded_bar
    volume_percent_container.shape_clip = true

    awful.tooltip {
        objects = { volume_percent_container },
        text = "[S] Audio Volume +/-"
    }

    timer {
        timeout = 0.1,
        autostart = true,
        callnow = true,
        callback = function()
            volume_percent.text = scripts.get_volume_info(3)
        end
    }

    volume_percent_container:connect_signal("button::press", function(_, _, _, button)
        if button == 4 then
            scripts.get_volume_info(1)
        elseif button == 5 then
            scripts.get_volume_info(-1)
        end
    end)

    local calendar_icon = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Material Bold 10",
        align  = "center",
        valign = "center",
        text   = ""
    }

    local calendar_icon_container = wibox.container.margin(calendar_icon, 5, 5, 0, 0)
    calendar_icon_container = wibox.container.background(calendar_icon_container)
    calendar_icon_container.bg = "#f9f9f9ee"
    calendar_icon_container.fg = "#434c5eff"
    calendar_icon_container.shape = gears.shape.circle
    calendar_icon_container.shape_clip = true

    awful.tooltip {
        objects = { calendar_icon_container },
        text = "Calendar"
    }

    calendar_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn("gsimplecal")
        end
    end)

    local date_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono JP 9",
        align  = "center",
        valign = "center"
    }

    local date_widget_container = wibox.container.margin(date_widget, 5, 5, 0, 0)
    date_widget_container = wibox.container.background(date_widget_container)
    date_widget_container.bg = "#434c5eee"
    date_widget_container.fg = "#f9f9f9ff"
    date_widget_container.shape = gears.shape.rounded_bar
    date_widget_container.shape_clip = true

    awful.tooltip {
        objects = { date_widget_container },
        text = "Date"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            date_widget.text = get_output_of_cmd("date +\"%Y年%m月%d日\"")
        end
    }

    local time_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font   = "Kurinto Mono 9",
        align  = "center",
        valign = "center"
    }

    local time_widget_container = wibox.container.margin(time_widget, 5, 5, 0, 0)
    time_widget_container = wibox.container.background(time_widget_container)
    time_widget_container.bg = "#434c5eee"
    time_widget_container.fg = "#f9f9f9ff"
    time_widget_container.shape = gears.shape.rounded_bar
    time_widget_container.shape_clip = true

    awful.tooltip {
        objects = { time_widget_container },
        text = "Time"
    }

    timer {
        timeout = 1,
        autostart = true,
        callnow = true,
        callback = function()
            time_widget.text = get_output_of_cmd("date +\"%H:%M:%S %p\"")
        end
    }

    local logout_logo = wibox.widget {
        {
            {
                markup = "󰍜",
                align  = "center",
                valign = "center",
                widget = wibox.widget.textbox,
                font   = "MesloLGS Nerd Font Mono 12"
            },
            margins = 2,
            widget = wibox.container.margin
        },
        widget = wibox.container.background,
        bg = "#f9f9f9ee",
        fg = "#434c5eff"
    }
    awful.tooltip {
        objects = { logout_logo },
        text = "[L] Session Menu [R] Extensions Menu"
    }

    logout_logo:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn.with_shell("~/.config/rofi/scripts/rofi-exts.sh session")
        elseif button == 3 then
            awful.spawn.with_shell("~/.config/rofi/scripts/rofi-exts.sh media")
        end
    end)

    logout_logo:connect_signal("mouse::enter", function()
        logout_logo.bg = "#f9f9f9cc"
    end)

    logout_logo:connect_signal("mouse::leave", function()
        logout_logo.bg = "#f9f9f9ee"
    end)

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
            time_widget_container,
            seperator,
            sep_left,
            logout_logo,
            sep_right
        }
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local function toggle_show_desktop()
    local current_tag = awful.screen.focused().selected_tag
    local client_on_tag = current_tag:clients()
    if #client_on_tag > 0 then
        local is_show = false
        for _, c in ipairs(client_on_tag) do
            if c:isvisible() then
                is_show = true
                break
            end
        end
        if is_show then
            for _, c in ipairs(client_on_tag) do
                if c:isvisible() then
                    c.minimized = true
                end
            end
        else
            for _, c in ipairs(client_on_tag) do
                if not c:isvisible() then
                    c.minimized = false
                end
            end
        end
    end
end

local switcher = require("awesome-switcher")

local globalkeys = gears.table.join(
-- Brightness controls --
    awful.key({}, "XF86MonBrightnessUp", function()
        scripts.change_brightness(1)
    end),
    awful.key({}, "XF86MonBrightnessDown", function()
        scripts.change_brightness(-1)
    end),
    -- Audio-volume controls --
    awful.key({}, "XF86AudioRaiseVolume", function()
        scripts.get_volume_info(1)
    end),
    awful.key({}, "XF86AudioLowerVolume", function()
        scripts.get_volume_info(-1)
    end),
    awful.key({}, "XF86AudioMute", function()
        scripts.get_volume_info(0)
    end),
    awful.key({}, "XF86AudioPlay", function()
        awful.spawn.with_shell("playerctl play-pause")
    end),
    awful.key({}, "XF86AudioNext", function()
        awful.spawn.with_shell("playerctl next")
    end),
    awful.key({}, "XF86AudioPrev", function()
        awful.spawn.with_shell("playerctl previous")
    end),
    awful.key({}, "XF86AudioStop", function()
        awful.spawn.with_shell("playerctl play-pause")
    end),
    awful.key({}, "XF86AudioPause", function()
        awful.spawn.with_shell("playerctl play-pause")
    end),
    -- Window controls --
    awful.key({ alt }, "Tab", function()
        switcher.switch(1, alt, "Alt_L", shift, "Tab")
    end),
    awful.key({ alt, shift }, "Tab", function()
        switcher.switch(-1, alt, "Alt_L", shift, "Tab")
    end),
    -- Rofi controls --
    awful.key({ super }, "Escape", function()
        awful.spawn.with_shell("~/.config/rofi/scripts/rofi-exts.sh session")
    end),
    awful.key({ alt }, "F1", function()
        awful.spawn.with_shell(
            "XMODIFIERS=@im=none rofi -theme-str '@import \"main.rasi\"' -no-lazy-grab -show drun -modi drun")
    end),
    -- Screenshot controls --
    awful.key({}, "Print", function()
        awful.spawn("flameshot")
    end),
    awful.key({ ctrl }, "Print", function()
        awful.spawn("flameshot gui")
    end),
    -- Applications --
    awful.key({ super }, "e", function()
        awful.spawn("thunar")
    end),
    awful.key({ super }, "l", function()
        awful.spawn("betterlockscreen -l blur")
    end),
    awful.key({ ctrl, alt }, "t", function()
        awful.spawn.with_shell("XMODIFIERS= alacritty")
    end),
    awful.key({ ctrl, shift }, "Escape", function()
        awful.spawn.with_shell("XMODIFIERS= alacritty -e btop")
    end),
    -- Awesome --
    awful.key({ super, ctrl }, "r", awesome.restart),
    awful.key({ super }, "d", toggle_show_desktop)
)

root.keys(globalkeys)

local clientkeys = gears.table.join(
    awful.key({ super, shift }, "Up", function(c)
            c:relative_move(0, -10, 0, 0)
    end),
    awful.key({ super, shift }, "Down", function(c)
            c:relative_move(0, 10, 0, 0)
    end),
    awful.key({ super, shift }, "Left", function(c)
            c:relative_move(-10, 0, 0, 0)
    end),
    awful.key({ super, shift }, "Right", function(c)
            c:relative_move(10, 0, 0, 0)
    end),
    -- Window controls --
    awful.key({ alt }, "F4", function(c)
        c:kill()
    end),
    awful.key({ super }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end),
    awful.key({ super }, "x", function(c)
        c.maximized = not c.maximized
        c:raise()
    end),
    awful.key({ super }, "z", function(c)
        c.minimized = not c.minimized
        if c.minimized then
            c:raise()
        end
    end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
-- for i = 1, 1 do
--     globalkeys = gears.table.join(globalkeys,
--         -- View tag only.
--         awful.key({ super }, "#" .. i + 9,
--                   function ()
--                         local screen = awful.screen.focused()
--                         local tag = screen.tags[i]
--                         if tag then
--                            tag:view_only()
--                         end
--                   end,
--                   {description = "view tag #"..i, group = "tag"}),
--         -- Toggle tag display.
--         awful.key({ super, ctrl }, "#" .. i + 9,
--                   function ()
--                       local screen = awful.screen.focused()
--                       local tag = screen.tags[i]
--                       if tag then
--                          awful.tag.viewtoggle(tag)
--                       end
--                   end,
--                   {description = "toggle tag #" .. i, group = "tag"}),
--         -- Move client to tag.
--         awful.key({ super, shift }, "#" .. i + 9,
--                   function ()
--                       if client.focus then
--                           local tag = client.focus.screen.tags[i]
--                           if tag then
--                               client.focus:move_to_tag(tag)
--                           end
--                      end
--                   end,
--                   {description = "move focused client to tag #"..i, group = "tag"}),
--         -- Toggle tag on focused client.
--         awful.key({ super, ctrl, shift }, "#" .. i + 9,
--                   function ()
--                       if client.focus then
--                           local tag = client.focus.screen.tags[i]
--                           if tag then
--                               client.focus:toggle_tag(tag)
--                           end
--                       end
--                   end,
--                   {description = "toggle focused client on tag #" .. i, group = "tag"})
--     )
-- end

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ super }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ super }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.centered
        }
    },
    {
        rule_any = {
            class = {
                "neovide"
            }
        },
        properties = {
            maximized = true,
        }
    }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
    local wa = c.screen.workarea
    if not c.fullscreen then
        c:geometry {
            x      = wa.x + margin_left,
            y      = wa.y + margin_top,
            width  = math.min(wa.width - margin_left - margin_right, c.width),
            height = math.min(wa.height - margin_top - margin_bottom, c.height)
        }
        awful.spawn("dunstctl set-paused false")
    else
        awful.spawn("dunstctl set-paused true")
    end
    c.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 6)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        {     -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

beautiful.focus_follows_mouse = false
beautiful.bg_systray = "#434c5e"

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
    local screen = c.screen
    if c.fullscreen then
        screen.mywibox.ontop = false
        awful.spawn("dunstctl set-paused true")
    else
        screen.mywibox.ontop = true
        awful.spawn("dunstctl set-paused false")
    end
end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

awful.spawn("wmname 'iamnanokaWM'")

client.connect_signal("request::geometry", function(c)
    local screen = c.screen
    local wa = screen.workarea

    if c.fullscreen then
        c.shape = gears.shape.rectangle
        return
    elseif c.maximized then
        -- Maximized nhưng vẫn có margin
        c:geometry {
            x      = wa.x + margin_left,
            y      = wa.y + margin_top,
            width  = wa.width - margin_left - margin_right,
            height = wa.height - margin_top - margin_bottom
        }
        c.shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, 10)
        end
    else
        -- Cửa sổ bình thường
        c:geometry {
            x      = wa.x + margin_left,
            y      = wa.y + margin_top,
            width  = math.min(wa.width - margin_left - margin_right, c.width),
            height = math.min(wa.height - margin_top - margin_bottom, c.height)
        }
        c.shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, 10)
        end
    end
end)

client.connect_signal("property::fullscreen", function(c)
    local screen = c.screen
    if c == screen.selected_tag then return end

    if c.fullscreen then
        screen.mywibox.ontop = false
        awful.spawn("dunstctl set-paused true")
    else
        screen.mywibox.ontop = true
        awful.spawn("dunstctl set-paused false")
    end
end)
