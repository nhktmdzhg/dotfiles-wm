-- Client signal handlers: geometry clamping, fullscreen handling and notification pausing.

---@diagnostic disable: undefined-global

local filesystem = require('gears.filesystem')
local gears = require('gears')
local notifications = require('config.notifications')

local icon_dir = '/usr/share/icons/BeautyLine/apps/scalable/'

local signals = {}

--- Constrains a value to a range.
-- @param x number Value to constrain.
-- @param min number Lower bound.
-- @param max number Upper bound.
-- @return number The constrained value.
local function clamp(x, min, max)
	return math.max(min, math.min(max, x))
end

--- Connects the client signal handlers.
-- @param vars table Shared constants from config.vars.
function signals.init(vars)
	local margin_top = vars.margin_top
	local margin_bottom = vars.margin_bottom
	local margin_left = vars.margin_left
	local margin_right = vars.margin_right

	--- Follows a client fullscreen state on the wibar and on the notification pause flag.
	-- @param c client Client whose fullscreen state changed.
	local function sync_fullscreen(c)
		local s = c.screen
		if c.fullscreen then
			s.mywibar.visible = false
			notifications.pause()
		else
			s.mywibar.visible = true
			if notifications.is_paused() then
				notifications.pause()
			else
				notifications.unpause()
			end
		end
	end

	-- Signals
	client.connect_signal('request::manage', function(c)
		local wa = c.screen.workarea
		if not c.fullscreen then
			c:geometry({
				x = math.max(wa.x + margin_left, c.x),
				y = math.max(wa.y + margin_top, c.y),
				width = math.min(wa.width - margin_left - margin_right, c.width),
				height = math.min(wa.height - margin_top - margin_bottom, c.height),
			})
			if notifications.is_paused() then
				notifications.pause()
			else
				notifications.unpause()
			end
		else
			notifications.pause()
		end
		local icon_path = icon_dir .. c.class .. '.svg'
		if filesystem.file_readable(icon_path) then
			c.icon = nil
		end
	end)

	client.connect_signal('focus', function(c)
		sync_fullscreen(c)
	end)

	client.connect_signal('request::geometry', function(c)
		local wa = c.screen.workarea

		if c.fullscreen then
			return
		elseif c.maximized then
			c:geometry({
				x = wa.x + margin_left,
				y = wa.y + margin_top,
				width = wa.width - margin_left - margin_right,
				height = wa.height - margin_top - margin_bottom,
			})
		else
			c:geometry({
				x = clamp(c.x, wa.x + margin_left, wa.x + wa.width - margin_right - c.width),
				y = clamp(c.y, wa.y + margin_top, wa.y + wa.height - margin_bottom - c.height),
				width = math.min(wa.width - margin_left - margin_right, c.width),
				height = math.min(wa.height - margin_top - margin_bottom, c.height),
			})
		end
	end)

	client.connect_signal('property::fullscreen', function(c)
		sync_fullscreen(c)
	end)
end

return signals
