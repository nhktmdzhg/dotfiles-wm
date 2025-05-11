local awful = require("awful")

local scripts = {}

local function get_output_of_cmd(cmd)
    local handle = io.popen(cmd)
    local result = handle and handle:read("*a") or ""
    if handle then
        handle:close()
    end
    return result
end

function scripts.get_battery_icon()
    local devices_output = get_output_of_cmd("upower -e")
    local battery_device

    for line in devices_output:gmatch("[^\n]+") do
        if line:match("BAT") then
            battery_device = line
            break
        end
    end

    if not battery_device then
        return nil
    end

    local info_output = get_output_of_cmd("upower -i " .. battery_device)

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
        return nil
    end

    local icons = {
        empty          = '',
        quarter        = '',
        half           = '',
        three_quarters = '',
        full           = '',
        charging       = ''
    }

    if status == "discharging" then
        if percentage <= 10 then
            return icons.empty
        elseif percentage <= 30 then
            return icons.quarter
        elseif percentage <= 50 then
            return icons.half
        elseif percentage <= 80 then
            return icons.three_quarters
        else
            return icons.full
        end
    else
        return icons.charging
    end
end

function scripts.get_battery_percent()
    local devices_output = get_output_of_cmd("upower -e")
    local battery_device

    for line in devices_output:gmatch("[^\n]+") do
        if line:match("BAT") then
            battery_device = line
            break
        end
    end

    if not battery_device then
        return nil
    end

    local info_output = get_output_of_cmd("upower -i " .. battery_device)

    for line in info_output:gmatch("[^\n]+") do
        if line:find("percentage:") then
            local percent_str = line:match("(%d+)%%")
            if percent_str then
                return tonumber(percent_str)
            else
                return nil
            end
        end
    end
end

function scripts.get_network_info(arg)
    local ethernet = get_output_of_cmd("ip addr show enp4s0")
    local ip_ethernet = ""
    for line in ethernet:gmatch("[^\n]+") do
        if line:find("inet ") then
            ip_ethernet = line:match("inet (%d+%.%d+%.%d+%.%d+)")
            break
        end
    end
    local essid = get_output_of_cmd("iwgetid -r")
    local icon, stat
    if ip_ethernet ~= "" then
        icon = ""
        stat = ip_ethernet
    elseif essid ~= "" then
        icon = ""
        stat = essid
    else
        icon = ""
        stat = "No Ethernet or Wi-Fi connected"
    end
    if arg == 0 then
        return icon
    elseif arg == 1 then
        return stat
    end
end

function scripts.get_volume_info(arg)
    if arg == 1 then
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")
    elseif arg == -1 then
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")
    elseif arg == 0 then
        awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
    end

    local vol_raw = get_output_of_cmd("pactl get-sink-volume @DEFAULT_SINK@")
    local volume
    for line in vol_raw:gmatch("[^\n]+") do
        local percent = line:match("(%d+)%%")
        if percent then
            volume = tonumber(percent) or 0
            break
        end
    end

    local mute_raw = get_output_of_cmd("pactl get-sink-mute @DEFAULT_SINK@")
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
        return icon
    elseif arg == 3 then
        return status or tostring(volume)
    else
        return nil
    end
end

function scripts.change_brightness(arg)
    local brightness_val = tonumber(get_output_of_cmd("brightnessctl g"):match("(%d+)"))
    if arg == 1 then
        awful.spawn("brightnessctl set 5%+ -q")
    elseif arg == -1 then
        awful.spawn("brightnessctl set 5%- -q")
    end

    local max_brightness = tonumber(get_output_of_cmd("brightnessctl m"):match("(%d+)"))
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
    awful.spawn("dunstify \"" ..
        brightness ..
        "\" -h \"int:value:" ..
        brightness .. "\" -a joyful_desktop -h string:synchronous:display-brightness -i " .. icon .. " -t 1000")
end

return scripts
