-- Shell command helpers: run one command asynchronously, report the parsed result via a callback.

local spawn = require('awful.spawn')
local string = require('gears.string')

local scripts = {}

local BATTERY_ICONS = {
	empty = '',
	quarter = '',
	half = '',
	three_quarters = '',
	full = '',
	charging = '',
}

--- Picks the battery icon for a discharging state and charge level.
-- @param status string State reported by upower, e.g. 'discharging' or 'fully-charged'.
-- @param percentage number Charge percentage.
-- @return string The icon to display.
local function battery_icon(status, percentage)
	if status ~= 'discharging' then
		return BATTERY_ICONS.charging
	end

	if percentage <= 10 then
		return BATTERY_ICONS.empty
	elseif percentage <= 30 then
		return BATTERY_ICONS.quarter
	elseif percentage <= 50 then
		return BATTERY_ICONS.half
	elseif percentage <= 80 then
		return BATTERY_ICONS.three_quarters
	end

	return BATTERY_ICONS.full
end

--- Reads the first battery reported by upower and reports its icon and charge.
-- @param callback function(icon, percent) Icon is '' without battery; percent may be 'AC'.
function scripts.get_battery_info(callback)
	local device

	spawn.with_line_callback({ 'upower', '-e' }, {
		stdout = function(line)
			if not device and line:match('BAT') then
				device = line
			end
		end,
		output_done = function()
			if not device then
				callback('', 'AC')
				return
			end

			local status, percentage

			spawn.with_line_callback({ 'upower', '-i', device }, {
				stdout = function(info_line)
					if string.startswith(info_line, '    state:') then
						status = info_line:match('state:%s+(%S+)')
					elseif not percentage and string.startswith(info_line, '    percentage:') then
						local percent_str = info_line:match('(%d+)%%')
						if percent_str then
							percentage = tonumber(percent_str)
						end
					end
				end,
				output_done = function()
					local icon = ''
					if status and percentage then
						icon = battery_icon(status, percentage)
					end
					callback(icon, percentage or 'AC')
				end,
			})
		end,
	})
end

--- Reports the network icon and status line, wired ethernet taking precedence over Wi-Fi.
-- @param callback function(icon, status) Called once both lookups are done.
function scripts.get_network_info(callback)
	local ip_ethernet = ''

	spawn.with_line_callback({ 'ip', 'addr', 'show', 'enp4s0' }, {
		stdout = function(line)
			if line:find('inet ') then
				ip_ethernet = line:match('inet (%d+%.%d+%.%d+%.%d+)') or ''
			end
		end,
		output_done = function()
			local essid = ''

			spawn.with_line_callback({ 'iwgetid', '-r' }, {
				stdout = function(line)
					essid = line
				end,
				output_done = function()
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

					callback(icon, stat)
				end,
			})
		end,
	})
end

--- Changes the default audio sink.
-- @param action string 'up' (+5%), 'down' (-5%) or 'toggle' (mute).
function scripts.set_volume(action)
	if action == 'up' then
		spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', '5%+' })
	elseif action == 'down' then
		spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', '5%-' })
	elseif action == 'toggle' then
		spawn({ 'wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle' })
	end
end

--- Reports the current volume icon and status, clamping the sink at 150%.
-- @param callback function(icon, status) Status is 'Muted' or the volume in percent.
function scripts.get_volume_info(callback)
	local volume = 0
	local muted = false

	spawn.with_line_callback({ 'wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@' }, {
		stdout = function(line)
			local vol_str = line:match('Volume: ([%d%.]+)')
			if vol_str then
				volume = math.floor(tonumber(vol_str) * 100)
			end
			if line:find('%[MUTED%]') then
				muted = true
			end
		end,
		output_done = function()
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
				spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', '150%' })
				icon = '󰕾'
			end

			callback(icon, status or tostring(volume))
		end,
	})
end

--- Steps the screen brightness and shows a notification with the new level.
-- @param arg number 1 to step up, -1 to step down; any other value only reports the current level.
function scripts.change_brightness(arg)
	local brightness_val

	spawn.with_line_callback({ 'brightnessctl', 'g' }, {
		stdout = function(line)
			brightness_val = tonumber(line:match('(%d+)'))
		end,
		output_done = function()
			if not brightness_val then
				return
			end

			if arg == 1 then
				spawn({ 'brightnessctl', 'set', '5%+', '-q' })
			elseif arg == -1 then
				spawn({ 'brightnessctl', 'set', '5%-', '-q' })
			end

			local max_brightness

			spawn.with_line_callback({ 'brightnessctl', 'm' }, {
				stdout = function(line)
					max_brightness = tonumber(line:match('(%d+)'))
				end,
				output_done = function()
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

					require('naughty').notification({
						title = tostring(brightness),
						app_icon = icon,
						timeout = 1,
					})
				end,
			})
		end,
	})
end

--- Reports the Proton VPN connection state.
-- @param callback function(status) Server name when connected, otherwise the disconnected icon.
function scripts.get_proton_vpn_info(callback)
	local connected = false
	local server_name

	spawn.with_line_callback({ 'pvpnctl', 'status' }, {
		stdout = function(line)
			if line:match('Status:%s+Connected') then
				connected = true
			else
				local server = line:match('Server:%s+(%S+)')
				if server then
					server_name = server
				end
			end
		end,
		output_done = function()
			if connected then
				callback(server_name or 'Connected')
			else
				callback('󰖂 ')
			end
		end,
	})
end

return scripts
