local spawn = require('awful.spawn')
local string = require('gears.string')

local scripts = {}

function scripts.get_battery_icon(callback)
	spawn.easy_async({ 'upower', '-e' }, function(stdout)
		local battery_device = nil

		for _, line in ipairs(string.split(stdout, '\n')) do
			if line:match('BAT') then
				battery_device = line
				break
			end
		end

		if not battery_device then
			callback(nil)
			return
		end

		spawn.easy_async({ 'upower', '-i', battery_device }, function(info_output)
			local status, percentage

			for _, line in ipairs(string.split(info_output, '\n')) do
				if string.startswith(line, '    state:') then
					status = line:match('state:%s+(%S+)')
				elseif string.startswith(line, '    percentage:') then
					local percent_str = line:match('(%d+)%%')
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
				charging = '',
			}

			local icon
			if status == 'discharging' then
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
	spawn.easy_async({ 'upower', '-e' }, function(stdout)
		local battery_device = nil

		for _, line in ipairs(string.split(stdout, '\n')) do
			if line:match('BAT') then
				battery_device = line
				break
			end
		end

		if not battery_device then
			callback(nil)
			return
		end

		spawn.easy_async({ 'upower', '-i', battery_device }, function(info_output)
			for _, line in ipairs(string.split(info_output, '\n')) do
				if string.startswith(line, '    percentage:') then
					local percent_str = line:match('(%d+)%%')
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
	spawn.easy_async({ 'ip', 'addr', 'show', 'enp4s0' }, function(ethernet_output)
		local ip_ethernet = ''

		for _, line in ipairs(string.split(ethernet_output, '\n')) do
			if line:find('inet ') then
				ip_ethernet = line:match('inet (%d+%.%d+%.%d+%.%d+)')
				break
			end
		end

		spawn.easy_async({ 'iwgetid', '-r' }, function(essid)
			local icon, stat

			if ip_ethernet ~= '' then
				icon = '󰈀'
				stat = 'Wired connection'
			elseif essid ~= '' then
				icon = '󰤨'
				stat = essid
			else
				icon = ''
				stat = 'No Ethernet or Wi-Fi connected'
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
		spawn({ 'pactl', 'set-sink-volume', '@DEFAULT_SINK@', '+5%' })
	elseif arg == -1 then
		spawn({ 'pactl', 'set-sink-volume', '@DEFAULT_SINK@', '-5%' })
	elseif arg == 0 then
		spawn({ 'pactl', 'set-sink-mute', '@DEFAULT_SINK@', 'toggle' })
	end

	spawn.easy_async({ 'pactl', 'get-sink-volume', '@DEFAULT_SINK@' }, function(vol_raw)
		local volume
		for _, line in ipairs(string.split(vol_raw, '\n')) do
			local percent = line:match('(%d+)%%')
			if percent then
				volume = tonumber(percent) or 0
				break
			end
		end

		spawn.easy_async({ 'pactl', 'get-sink-mute', '@DEFAULT_SINK@' }, function(mute_raw)
			local muted = false
			for _, line in ipairs(string.split(mute_raw, '\n')) do
				if string.startswith(line, 'Mute:') then
					muted = line:find('yes') ~= nil
					break
				end
			end

			local icon, status

			if volume == 0 or muted then
				icon = '󰖁'
				status = 'Muted'
			elseif volume < 30 then
				icon = ''
			elseif volume < 70 then
				icon = '󰖀'
			elseif volume <= 150 then
				icon = '󰕾'
			else
				spawn({ 'pactl', 'set-sink-volume', '@DEFAULT_SINK@', '150%' })
				icon = '󰕾'
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
	spawn.easy_async({ 'brightnessctl', 'g' }, function(brightness_output)
		local brightness_val = tonumber(brightness_output:match('(%d+)'))

		if not brightness_val then
			return
		end

		if arg == 1 then
			spawn({ 'brightnessctl', 'set', '5%+', '-q' })
		elseif arg == -1 then
			spawn({ 'brightnessctl', 'set', '5%-', '-q' })
		end
		spawn.easy_async({ 'brightnessctl', 'm' }, function(max_output)
			local max_brightness = tonumber(max_output:match('(%d+)'))

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

			spawn({
				'notify-send',
				tostring(brightness),
				'--hint',
				'int:value:' .. brightness,
				'--hint',
				'string:synchronous:display-brightness',
				'-i',
				icon,
				'-t',
				'1000',
			})
		end)
	end)
end

return scripts
