-- Single shared gears.timer that drives every periodic task of this configuration.

local protected_call = require('gears.protected_call')
local timer = require('gears.timer')

local poller = {}

local TICK = 0.1

local ticks = 0
local entries = {}
local ticker

--- Registers a callback on the shared tick timer and runs it once immediately.
-- @param interval number Seconds between runs; must be a multiple of the 0.1s tick.
-- @param callback function Called on the timer tick.
function poller.every(interval, callback)
	local period = math.floor(interval / TICK + 0.5)
	if period < 1 or math.abs(period * TICK - interval) > 1e-9 then
		error('poller.every: interval must be multiple of ' .. TICK .. ' (get ' .. tostring(interval) .. ')')
	end

	entries[#entries + 1] = { period = period, callback = callback }

	if not ticker then
		ticker = timer({ timeout = TICK, autostart = true })
		ticker:connect_signal('timeout', function()
			ticks = ticks + 1
			for i = 1, #entries do
				local entry = entries[i]
				if ticks % entry.period == 0 then
					protected_call(entry.callback)
				end
			end
		end)
	end

	protected_call(callback)
end

return poller
