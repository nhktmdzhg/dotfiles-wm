---@diagnostic disable: undefined-global
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local timer = require("gears.timer")
local scripts = require("scripts")
require("awful.hotkeys_popup.keys")
local palette = require("mocha")

local super = "Mod4"
local alt = "Mod1"
local ctrl = "Control"
local shift = "Shift"
local margin_top = 10
local margin_bottom = 10
local margin_left = 10
local margin_right = 10
local wibox_height = 30
local wibox_margin = 5

local function spawn_once(cmd_name, cmd_full)
    awful.spawn.with_shell("pgrep -u $USER -x " .. cmd_name .. " > /dev/null; or exec " .. cmd_full)
end

package.loaded["naughty.dbus"] = {}
spawn_once("dunst", "dunst")
awful.spawn("pactl set-source-volume @DEFAULT_SOURCE@ 150%")
awful.spawn("ksuperkey -e 'Super_L=Alt_L|F2'")
awful.spawn("ksuperkey -e 'Super_R=Alt_L|F2'")
spawn_once("picom", "picom --animations -b")
spawn_once("lxqt-policykit-", "lxqt-policykit-agent")
spawn_once("xss-lock", "xss-lock -q -l ~/.config/awesome/xss-lock-tsl.sh")
awful.spawn("xset s off")
awful.spawn("xset -dpms")
spawn_once("thunderbird", "thunderbird")
spawn_once("mcontrolcenter", "mcontrolcenter")
spawn_once("Discord", "discord")
spawn_once("zalo", "zalo")
spawn_once("fcitx5", "fcitx5")
awful.spawn.once("bluetoothctl power off")

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

awful.layout.layouts = {awful.layout.suit.floating}

-- Wibar
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

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate", "tasklist", {
            raise = true
        })
    end
end))

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
    awful.tag({"1"}, s, awful.layout.layouts[1])

    -- Create the wibox
    s.mywibox = wibox({
        position = "top",
        screen = s,
        width = s.geometry.width - 10,
        height = wibox_height,
        x = wibox_margin,
        y = wibox_margin,
        bg = "#00000000",
        fg = "#ffffff",
        ontop = true,
        visible = true
    })

    s.mytasklist = awful.widget.tasklist {
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

    local constrained_tasklist = wibox.container.constraint(s.mytasklist, "exact", nil, 32)

    -- Custom widgets
    local sep_left = wibox.widget {
        markup = "",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Iosevka 14"
    }

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
        objects = {arch_logo},
        text = "[L] Main Menu [R] Extensions Menu"
    }

    arch_logo:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn.with_shell(
                "XMODIFIERS=@im=none exec rofi -no-lazy-grab -show drun -modi drun")
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

    local seperator = wibox.widget {
        widget = wibox.widget.separator,
        orientation = "vertical",
        forced_width = 6,
        color = "#00000000"
    }

    local sep_right = wibox.widget {
        markup = '',
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
        font = "Iosevka 14"
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
    mysystray.bg = palette.surface0.hex
    mysystray.shape = gears.shape.rounded_bar
    mysystray.shape_clip = true

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
        objects = {window_name_container},
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
        -- font = "JetBrainsMono Nerd Font 10",
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
        objects = {battery_icon_container},
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
        objects = {battery_percent_container},
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
        objects = {network_icon_container},
        text = "Network Status"
    }

    network_icon_container:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn.with_shell("XMODIFIERS= exec alacritty -e nmcurse")
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
            network_icon.text = scripts.get_network_info(0)
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
        objects = {network_status_container},
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
        objects = {volume_icon_container},
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
        objects = {volume_percent_container},
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
        objects = {calendar_icon_container},
        text = "Calendar"
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
        objects = {date_widget_container},
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
        objects = {time_widget_container},
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

    -- Add widgets to the wibox
    s.mywibox:setup{
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

-- Mouse bindings
-- root.buttons(gears.table.join(awful.button({}, 4, awful.tag.viewnext), awful.button({}, 5, awful.tag.viewprev)))

-- Key bindings
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

local globalkeys = gears.table.join( -- Brightness controls --
awful.key({}, "XF86MonBrightnessUp", function()
    scripts.change_brightness(1)
end), awful.key({}, "XF86MonBrightnessDown", function()
    scripts.change_brightness(-1)
end), -- Audio-volume controls --
awful.key({}, "XF86AudioRaiseVolume", function()
    scripts.get_volume_info(1)
end), awful.key({}, "XF86AudioLowerVolume", function()
    scripts.get_volume_info(-1)
end), awful.key({}, "XF86AudioMute", function()
    scripts.get_volume_info(0)
end), awful.key({}, "XF86AudioPlay", function()
    awful.spawn("playerctl play-pause")
end), awful.key({}, "XF86AudioNext", function()
    awful.spawn("playerctl next")
end), awful.key({}, "XF86AudioPrev", function()
    awful.spawn("playerctl previous")
end), awful.key({}, "XF86AudioStop", function()
    awful.spawn("playerctl play-pause")
end), awful.key({}, "XF86AudioPause", function()
    awful.spawn("playerctl play-pause")
end), -- Window controls --
awful.key({alt}, "Tab", function()
    switcher.switch(1, alt, "Alt_L", shift, "Tab")
end), awful.key({alt, shift}, "Tab", function()
    switcher.switch(-1, alt, "Alt_L", shift, "Tab")
end),  -- Menu controls --
awful.key({super}, "Escape", function()
    awful.spawn("wlogout")
end), awful.key({alt}, "F2", function()
    awful.spawn.with_shell(
        "XMODIFIERS=@im=none exec rofi -no-lazy-grab -show drun -modi drun")
end), -- Screenshot controls --
awful.key({}, "Print", function()
    awful.spawn("flameshot")
end), awful.key({ctrl}, "Print", function()
    awful.spawn("flameshot gui")
end), -- Applications --
awful.key({super}, "e", function()
    awful.spawn("thunar")
end), awful.key({super}, "l", function()
    awful.spawn("betterlockscreen -l blur")
end), awful.key({ctrl, alt}, "t", function()
    awful.spawn.with_shell("XMODIFIERS= exec alacritty")
end), awful.key({ctrl, shift}, "Escape", function()
    awful.spawn.with_shell("XMODIFIERS= exec alacritty -e btop")
end), -- Awesome --
awful.key({super, ctrl}, "r", awesome.restart), awful.key({super}, "d", toggle_show_desktop),
    awful.key({super}, "b", function()
        awful.spawn("librewolf")
    end), awful.key({super}, "n", function()
        awful.spawn("nvim-qt")
    end))

root.keys(globalkeys)

local clientkeys = gears.table.join(awful.key({super, shift}, "Up", function(c)
    c:relative_move(0, -10, 0, 0)
end), awful.key({super, shift}, "Down", function(c)
    c:relative_move(0, 10, 0, 0)
end), awful.key({super, shift}, "Left", function(c)
    c:relative_move(-10, 0, 0, 0)
end), awful.key({super, shift}, "Right", function(c)
    c:relative_move(10, 0, 0, 0)
end), awful.key({super}, "Up", function(c)
    local screen = c.screen
    local wa = screen.workarea
    c:geometry{
        x = wa.x + margin_left,
        y = wa.y + margin_top + wibox_height + wibox_margin,
        width = wa.width - margin_left - margin_right,
        height = (wa.height - margin_top - margin_bottom - wibox_height - wibox_margin) / 2
    }
end), awful.key({super}, "Down", function(c)
    local screen = c.screen
    local wa = screen.workarea
    local height = (wa.height - margin_top - margin_bottom - wibox_height - wibox_margin) / 2
    c:geometry{
        x = wa.x + margin_left,
        y = wa.y + margin_top + wibox_height + wibox_margin + height,
        width = wa.width - margin_left - margin_right,
        height = height
    }
end), awful.key({super}, "Left", function(c)
    local screen = c.screen
    local wa = screen.workarea
    c:geometry{
        x = wa.x + margin_left,
        y = wa.y + margin_top + wibox_height + wibox_margin,
        width = (wa.width - margin_left - margin_right) / 2,
        height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
    }
end), awful.key({super}, "Right", function(c)
    local screen = c.screen
    local wa = screen.workarea
    local width = (wa.width - margin_left - margin_right) / 2
    c:geometry{
        x = wa.x + margin_left + width,
        y = wa.y + margin_top + wibox_height + wibox_margin,
        width = width,
        height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
    }
end), -- Window controls --
awful.key({alt}, "F4", function(c)
    c:kill()
end), awful.key({super}, "f", function(c)
    c.fullscreen = not c.fullscreen
end), awful.key({super}, "x", function(c)
    c.maximized = not c.maximized
end), awful.key({super}, "z", function(c)
    c.minimized = true
    c:lower()
end))

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

local clientbuttons = gears.table.join(awful.button({}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
end), awful.button({super}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.move(c)
end), awful.button({super}, 3, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.resize(c)
end))

-- Set keys
root.keys(globalkeys)

-- Rules
awful.rules.rules = {{
    rule = {},
    properties = {
        border_width = 0,
        border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        screen = awful.screen.preferred,
        callback = function(c)
            awful.placement.centered(c, nil)
        end
    }
}, {
    rule_any = {
        class = {"nvim-qt", "VSCodium"}
    },
    properties = {
        maximized = true
    }
}, {
    rule_any = {
        type = {"splash", "dialog"}
    },
    properties = {
        skip_taskbar = true,
        callback = function(c)
            awful.placement.centered(c, nil)
        end
    }
}, {
    rule_any = {
        type = {"menu", "popup_menu", "dropdown_menu", "combo"}
    },
    properties = {
        skip_taskbar = true,
        -- placement = awful.placement.resize_to_mouse
        callback = function(c)
            awful.placement.resize_to_mouse(c, nil)
        end
    }
}, {
    rule_any = {
        class = {"Gsimplecal", "gsimplecal"}
    },
    properties = {
        skip_taskbar = true,
        callback = function(c)
            awful.placement.resize_to_mouse(c, nil)
        end
    }
}}

-- Signals
client.connect_signal("manage", function(c)
    local wa = c.screen.workarea
    if not c.fullscreen then
        c:geometry{
            x = math.max(wa.x + margin_left, c.x),
            y = math.max(wa.y + margin_top + wibox_height + wibox_margin, c.y),
            width = math.min(wa.width - margin_left - margin_right, c.width),
            height = math.min(wa.height - margin_top - margin_bottom - wibox_height - wibox_margin, c.height)
        }
        awful.spawn("dunstctl set-paused false")
    else
        awful.spawn("dunstctl set-paused true")
    end
end)

-- Request titlebar 
-- client.connect_signal("request::titlebars", function(c)
--     -- buttons for the titlebar
--     local buttons = gears.table.join(awful.button({}, 1, function()
--         c:emit_signal("request::activate", "titlebar", {
--             raise = true
--         })
--         awful.mouse.client.move(c)
--     end), awful.button({}, 3, function()
--         c:emit_signal("request::activate", "titlebar", {
--             raise = true
--         })
--         awful.mouse.client.resize(c)
--     end))
--
--     awful.titlebar(c):setup{
--         { -- Left
--             awful.titlebar.widget.iconwidget(c),
--             buttons = buttons,
--             layout = wibox.layout.fixed.horizontal
--         },
--         { -- Middle
--             { -- Title
--                 align = "center",
--                 widget = awful.titlebar.widget.titlewidget(c)
--             },
--             buttons = buttons,
--             layout = wibox.layout.flex.horizontal
--         },
--         { -- Right
--             awful.titlebar.widget.maximizedbutton(c),
--             awful.titlebar.widget.stickybutton(c),
--             awful.titlebar.widget.ontopbutton(c),
--             awful.titlebar.widget.closebutton(c),
--             layout = wibox.layout.fixed.horizontal()
--         },
--         layout = wibox.layout.align.horizontal
--     }
-- end)

beautiful.focus_follows_mouse = false
beautiful.bg_systray = palette.surface0.hex

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
    local screen = c.screen
    if c.fullscreen then
        screen.mywibox.visible = false
        awful.spawn("dunstctl set-paused true")
    else
        screen.mywibox.visible = true
        awful.spawn("dunstctl set-paused false")
    end
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)

local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

client.connect_signal("request::geometry", function(c)
    local screen = c.screen
    local wa = screen.workarea

    if c.fullscreen then
        return
    elseif c.maximized then
        c:geometry{
            x = wa.x + margin_left,
            y = wa.y + margin_top + wibox_height + wibox_margin,
            width = wa.width - margin_left - margin_right,
            height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
        }
    else
        c:geometry{
            x = clamp(c.x, wa.x + margin_left, wa.x + wa.width - margin_right - c.width),
            y = clamp(c.y, wa.y + margin_top + wibox_height + wibox_margin, wa.y + wa.height - margin_bottom - c.height),
            width = math.min(wa.width - margin_left - margin_right, c.width),
            height = math.min(wa.height - margin_top - margin_bottom - wibox_height - wibox_margin, c.height)
        }
    end
end)

client.connect_signal("property::fullscreen", function(c)
    local screen = c.screen
    if c == screen.selected_tag then
        return
    end

    if c.fullscreen then
        screen.mywibox.visible = false
        awful.spawn("dunstctl set-paused true")
    else
        screen.mywibox.visible = true
        awful.spawn("dunstctl set-paused false")
    end
end)

-- Tasklist color
beautiful.tasklist_bg_focus = palette.surface0.hex
beautiful.tasklist_bg_normal = "#00000000"
beautiful.tasklist_bg_urgent = palette.red.hex
beautiful.tasklist_bg_minimize = "#00000000"
beautiful.tasklist_shape_focus = gears.shape.rectangle
