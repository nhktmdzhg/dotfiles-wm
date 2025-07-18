local gears = require("gears")
local awful = require("awful")
local scripts = require("scripts")
local awesome = require("awesome")

local keys = {}

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

function keys.init(vars)
    local super = vars.super
    local alt = vars.alt
    local ctrl = vars.ctrl
    local shift = vars.shift
    local home = vars.home
    local margin_top = vars.margin_top
    local margin_bottom = vars.margin_bottom
    local margin_left = vars.margin_left
    local margin_right = vars.margin_right
    local wibox_height = vars.wibox_height
    local wibox_margin = vars.wibox_margin

    local switcher = require("awesome-switcher")

    local globalkeys = gears.table.join( -- Brightness controls --
        awful.key({}, "XF86MonBrightnessUp", function()
            scripts.change_brightness(1)
        end),
        awful.key({}, "XF86MonBrightnessDown", function()
            scripts.change_brightness(-1)
        end), -- Audio-volume controls --
        awful.key({}, "XF86AudioRaiseVolume", function()
            scripts.get_volume_info(1, nil)
        end),
        awful.key({}, "XF86AudioLowerVolume", function()
            scripts.get_volume_info(-1, nil)
        end),
        awful.key({}, "XF86AudioMute", function()
            scripts.get_volume_info(0, nil)
        end),
        awful.key({}, "XF86AudioPlay", function()
            awful.spawn({ "playerctl", "play-pause" })
        end),
        awful.key({}, "XF86AudioNext", function()
            awful.spawn({ "playerctl", "next" })
        end),
        awful.key({}, "XF86AudioPrev", function()
            awful.spawn({ "playerctl", "previous" })
        end),
        awful.key({}, "XF86AudioStop", function()
            awful.spawn({ "playerctl", "play-pause" })
        end),
        awful.key({}, "XF86AudioPause", function()
            awful.spawn({ "playerctl", "play-pause" })
        end), -- Window controls --
        awful.key({ alt }, "Tab", function()
            switcher.switch(1, alt, "Alt_L", shift, "Tab")
        end),
        awful.key({ alt, shift }, "Tab", function()
            switcher.switch(-1, alt, "Alt_L", shift, "Tab")
        end), -- Menu controls --
        awful.key({ super }, "Escape", function()
            awful.spawn("wlogout")
        end),
        awful.key({ alt }, "F2", function()
            awful.spawn({ "env", "XMODIFIERS=@im=none", "rofi", "-no-lazy-grab", "-show", "drun" })
        end), -- Screenshot controls --
        awful.key({ ctrl }, "Print", function()
            awful.spawn({ "flameshot", "gui" })
        end),
        awful.key({}, "Print", function()
            awful.spawn({ "flameshot", "full" })
        end), -- Applications --
        awful.key({ super }, "e", function()
            awful.spawn("thunar")
        end),
        awful.key({ super }, "l", function()
            awful.spawn({ home .. "/.config/awesome/xss-lock-tsl.sh" })
        end),
        awful.key({ ctrl, alt }, "t", function()
            awful.spawn({ "wezterm" })
        end),
        awful.key({ ctrl, shift }, "Escape", function()
            awful.spawn({ "wezterm", "-e", "btop" })
        end), -- Awesome --
        awful.key({ super, ctrl }, "r", awesome.restart),
        awful.key({ super }, "d", toggle_show_desktop),
        awful.key({ super }, "b", function()
            awful.spawn("zen-browser")
        end),
        awful.key({ super }, "n", function()
            awful.spawn("nvim-qt")
        end),
        awful.key({ super }, "c", function()
            awful.spawn("discord")
        end))

    local clientkeys = gears.table.join(awful.key({ super, shift }, "Up", function(c)
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
        awful.key({ super }, "Up", function(c)
            local wa = c.screen.workarea
            c:geometry {
                x = wa.x + margin_left,
                y = wa.y + margin_top + wibox_height + wibox_margin,
                width = wa.width - margin_left - margin_right,
                height = (wa.height - margin_top - margin_bottom - wibox_height - wibox_margin) / 2
            }
        end),
        awful.key({ super }, "Down", function(c)
            local wa = c.screen.workarea
            local height = (wa.height - margin_top - margin_bottom - wibox_height - wibox_margin) / 2
            c:geometry {
                x = wa.x + margin_left,
                y = wa.y + margin_top + wibox_height + wibox_margin + height,
                width = wa.width - margin_left - margin_right,
                height = height
            }
        end),
        awful.key({ super }, "Left", function(c)
            local wa = c.screen.workarea
            c:geometry {
                x = wa.x + margin_left,
                y = wa.y + margin_top + wibox_height + wibox_margin,
                width = (wa.width - margin_left - margin_right) / 2,
                height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
            }
        end),
        awful.key({ super }, "Right", function(c)
            local wa = c.screen.workarea
            local width = (wa.width - margin_left - margin_right) / 2
            c:geometry {
                x = wa.x + margin_left + width,
                y = wa.y + margin_top + wibox_height + wibox_margin,
                width = width,
                height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
            }
        end), -- Window controls --
        awful.key({ alt }, "F4", function(c)
            c:kill()
        end),
        awful.key({ super }, "f", function(c)
            c.fullscreen = not c.fullscreen
        end),
        awful.key({ super }, "x", function(c)
            c.maximized = not c.maximized
        end),
        awful.key({ super }, "z", function(c)
            c.minimized = true
            c:lower()
        end))

    local clientbuttons = gears.table.join(awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {
            raise = true
        })
    end), awful.button({ super }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {
            raise = true
        })
        awful.mouse.client.move(c)
    end), awful.button({ super }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", {
            raise = true
        })
        awful.mouse.client.resize(c)
    end))

    return {
        globalkeys = globalkeys,
        clientkeys = clientkeys,
        clientbuttons = clientbuttons
    }
end

return keys
