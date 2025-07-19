local rules_module = require("awful.rules")
local client = require("awful.client")
local screen = require("awful.screen")
local placement = require("awful.placement")

local rules = {}

function rules.init(keys)
    rules_module.rules = { {
        rule = {},
        properties = {
            border_width = 0,
            focus = client.focus.filter,
            raise = true,
            keys = keys.clientkeys,
            buttons = keys.clientbuttons,
            screen = screen.preferred,
            callback = function(c)
                placement.centered(c, nil)
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
                placement.centered(c, nil)
            end
        }
    }, {
        rule_any = {
            type = { "menu", "popup_menu", "dropdown_menu", "combo" }
        },
        properties = {
            skip_taskbar = true,
            -- placement = placement.resize_to_mouse
            callback = function(c)
                placement.resize_to_mouse(c, nil)
            end
        }
    }, {
        rule_any = {
            class = { "Gsimplecal", "gsimplecal" }
        },
        properties = {
            skip_taskbar = true,
            callback = function(c)
                placement.resize_to_mouse(c, nil)
            end
        }
    } }
end

return rules
