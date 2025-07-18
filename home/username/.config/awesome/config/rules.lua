local awful = require("awful")

local rules = {}

function rules.init(keys)
    awful.rules.rules = { {
        rule = {},
        properties = {
            border_width = 0,
            focus = awful.client.focus.filter,
            raise = true,
            keys = keys.clientkeys,
            buttons = keys.clientbuttons,
            screen = awful.screen.preferred,
            callback = function(c)
                awful.placement.centered(c, nil)
            end
        }
    }, {
        rule_any = {
            class = { "nvim-qt", "Code" }
        },
        properties = {
            maximized = true
        }
    }, {
        rule_any = {
            type = { "splash", "dialog" }
        },
        properties = {
            skip_taskbar = true,
            callback = function(c)
                awful.placement.centered(c, nil)
            end
        }
    }, {
        rule_any = {
            type = { "menu", "popup_menu", "dropdown_menu", "combo" }
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
            class = { "Gsimplecal", "gsimplecal" }
        },
        properties = {
            skip_taskbar = true,
            callback = function(c)
                awful.placement.resize_to_mouse(c, nil)
            end
        }
    } }
end

return rules
