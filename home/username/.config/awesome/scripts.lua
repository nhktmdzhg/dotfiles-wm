local awful = require("awful")

local scripts = {}

function scripts.get_battery_icon(callback)
    awful.spawn.easy_async("upower -e", function(stdout)
        local battery_device = nil

        for line in stdout:gmatch("[^\n]+") do
            if line:match("BAT") then
                battery_device = line
                break
            end
        end

        if not battery_device then
            callback(nil)
            return
        end

        awful.spawn.easy_async("upower -i " .. battery_device, function(info_output)
            local status, percentage

            for line in info_output:gmatch("[^\n]+") do
                if line:find("state:") then
                    status = line:match("state:%s+(%S+)")
                elseif line:find("percentage:") then
                    local percent_str = line:match("(%d+)%%")
                    if percent_str then
                        percentage = tonumber(percent_str)
                    end
                end
            end

            if not status or not percentage then
                callback(nil)
                return
            end

            local icons = {
                empty = '',
                quarter = '',
                half = '',
                three_quarters = '',
                full = '',
                charging = ''
            }

            local icon
            if status == "discharging" then
                if percentage <= 10 then
                    icon = icons.empty
                elseif percentage <= 30 then
                    icon = icons.quarter
                elseif percentage <= 50 then
                    icon = icons.half
                elseif percentage <= 80 then
                    icon = icons.three_quarters
                else
                    icon = icons.full
                end
            else
                icon = icons.charging
            end

            callback(icon)
        end)
    end)
end

function scripts.get_battery_percent(callback)
    awful.spawn.easy_async("upower -e", function(stdout)
        local battery_device = nil

        for line in stdout:gmatch("[^\n]+") do
            if line:match("BAT") then
                battery_device = line
                break
            end
        end

        if not battery_device then
            callback(nil)
            return
        end

        awful.spawn.easy_async("upower -i " .. battery_device, function(info_output)
            for line in info_output:gmatch("[^\n]+") do
                if line:find("percentage:") then
                    local percent_str = line:match("(%d+)%%")
                    if percent_str then
                        callback(tonumber(percent_str))
                        return
                    else
                        callback(nil)
                        return
                    end
                end
            end
            callback(nil)
        end)
    end)
end

function scripts.get_network_info(arg, callback)
    awful.spawn.easy_async("ip addr show enp4s0", function(ethernet_output)
        local ip_ethernet = ""

        for line in ethernet_output:gmatch("[^\n]+") do
            if line:find("inet ") then
                ip_ethernet = line:match("inet (%d+%.%d+%.%d+%.%d+)")
                break
            end
        end

        awful.spawn.easy_async("iwgetid -r", function(essid)
            local icon, stat

            if ip_ethernet ~= "" then
                icon = ""
                stat = "Wired connection"
            elseif essid ~= "" then
                icon = ""
                stat = essid
            else
                icon = ""
                stat = "No Ethernet or Wi-Fi connected"
            end

            if arg == 0 then
                callback(icon)
            elseif arg == 1 then
                callback(stat)
            else
                callback(nil)
            end
        end)
    end)
end

function scripts.get_volume_info(arg, callback)
    if arg == 1 then
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")
    elseif arg == -1 then
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")
    elseif arg == 0 then
        awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
    end

    awful.spawn.easy_async("pactl get-sink-volume @DEFAULT_SINK@", function(vol_raw)
        local volume
        for line in vol_raw:gmatch("[^\n]+") do
            local percent = line:match("(%d+)%%")
            if percent then
                volume = tonumber(percent) or 0
                break
            end
        end

        awful.spawn.easy_async("pactl get-sink-mute @DEFAULT_SINK@", function(mute_raw)
            local muted = false
            for line in mute_raw:gmatch("[^\n]+") do
                if line:lower():find("mute:") then
                    muted = line:find("yes") ~= nil
                    break
                end
            end

            local icon, status

            if volume == 0 or muted then
                icon = ""
                status = "Muted"
            elseif volume < 30 then
                icon = ""
            elseif volume < 70 then
                icon = ""
            elseif volume <= 150 then
                icon = ""
            else
                awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ 150%")
                icon = ""
            end

            if arg == 2 then
                callback(icon)
            elseif arg == 3 then
                callback(status or tostring(volume))
            else
                callback(nil)
            end
        end)
    end)
end

function scripts.change_brightness(arg)
    awful.spawn.easy_async("brightnessctl g", function(brightness_output)
        local brightness_val = tonumber(brightness_output:match("(%d+)"))

        if not brightness_val then
            return
        end

        if arg == 1 then
            awful.spawn("brightnessctl set 5%+ -q")
        elseif arg == -1 then
            awful.spawn("brightnessctl set 5%- -q")
        end

        awful.spawn.easy_async("brightnessctl m", function(max_output)
            local max_brightness = tonumber(max_output:match("(%d+)"))

            if not max_brightness then
                return
            end

            local brightness = math.floor((brightness_val / max_brightness) * 100)
            if arg == 1 then
                brightness = math.min(brightness + 5, 100)
            elseif arg == -1 then
                brightness = math.max(brightness - 5, 0)
            end

            local icon
            if brightness <= 10 then
                icon = 'display-brightness-low'
            elseif brightness <= 70 then
                icon = 'display-brightness-medium'
            else
                icon = 'display-brightness-high'
            end

            awful.spawn("dunstify \"" .. brightness .. "\" -h \"int:value:" .. brightness ..
                            "\" -h string:synchronous:display-brightness -i " .. icon .. " -t 1000")
        end)
    end)
end

return scripts
