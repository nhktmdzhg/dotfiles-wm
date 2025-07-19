local spawn = require("awful.spawn")
local client = require("client")

local signals = {}

local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function signals.init(vars)
    local margin_top = vars.margin_top
    local margin_bottom = vars.margin_bottom
    local margin_left = vars.margin_left
    local margin_right = vars.margin_right
    local wibox_height = vars.wibox_height
    local wibox_margin = vars.wibox_margin

    -- Signals
    client.connect_signal("manage", function(c)
        local wa = c.screen.workarea
        if not c.fullscreen then
            c:geometry {
                x = math.max(wa.x + margin_left, c.x),
                y = math.max(wa.y + margin_top + wibox_height + wibox_margin, c.y),
                width = math.min(wa.width - margin_left - margin_right, c.width),
                height = math.min(wa.height - margin_top - margin_bottom - wibox_height - wibox_margin, c.height)
            }
            spawn({ "dunstctl", "set-paused", "false" })
        else
            spawn({ "dunstctl", "set-paused", "true" })
        end
    end)

    client.connect_signal("focus", function(c)
        local screen = c.screen
        if c.fullscreen then
            screen.mywibox.visible = false
            spawn({ "dunstctl", "set-paused", "true" })
        else
            screen.mywibox.visible = true
            spawn({ "dunstctl", "set-paused", "false" })
        end
    end)

    client.connect_signal("request::geometry", function(c)
        local wa = c.screen.workarea

        if c.fullscreen then
            return
        elseif c.maximized then
            c:geometry {
                x = wa.x + margin_left,
                y = wa.y + margin_top + wibox_height + wibox_margin,
                width = wa.width - margin_left - margin_right,
                height = wa.height - margin_top - margin_bottom - wibox_height - wibox_margin
            }
        else
            c:geometry {
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
            spawn({ "dunstctl", "set-paused", "true" })
        else
            screen.mywibox.visible = true
            spawn({ "dunstctl", "set-paused", "false" })
        end
    end)
end

return signals
