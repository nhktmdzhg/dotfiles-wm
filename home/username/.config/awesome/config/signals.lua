local client = require('client')
local gears = require('gears')
local spawn = require('awful.spawn')

local signals = {}

local dunst_paused = false

local function clamp(x, min, max)
	return math.max(min, math.min(max, x))
end

function signals.toggle_dunst()
	dunst_paused = not dunst_paused
	if client.focus.fullscreen then
		return
	end
	if dunst_paused then
		spawn({ 'dunstctl', 'set-paused', 'true' })
	else
		spawn({ 'dunstctl', 'set-paused', 'false' })
	end
end

function signals.is_dunst_paused()
	return dunst_paused
end

function signals.init(vars)
	local margin_top = vars.margin_top
	local margin_bottom = vars.margin_bottom
	local margin_left = vars.margin_left
	local margin_right = vars.margin_right

	-- Signals
	client.connect_signal('manage', function(c)
		local wa = c.screen.workarea
		if not c.fullscreen then
			c:geometry({
				x = math.max(wa.x + margin_left, c.x),
				y = math.max(wa.y + margin_top, c.y),
				width = math.min(wa.width - margin_left - margin_right, c.width),
				height = math.min(wa.height - margin_top - margin_bottom, c.height),
			})
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		else
			spawn({ 'dunstctl', 'set-paused', 'true' })
		end
		c.shape = function(cr, w, h)
			gears.shape.rounded_rect(cr, w, h, 11)
		end
	end)

	client.connect_signal('focus', function(c)
		local screen = c.screen
		if c.fullscreen then
			screen.mywibar.visible = false
			spawn({ 'dunstctl', 'set-paused', 'true' })
		else
			screen.mywibar.visible = true
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		end
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
		local screen = c.screen
		if c == screen.selected_tag then
			return
		end

		if c.fullscreen then
			screen.mywibar.visible = false
			spawn({ 'dunstctl', 'set-paused', 'true' })
		else
			screen.mywibar.visible = true
			if dunst_paused then
				spawn({ 'dunstctl', 'set-paused', 'true' })
			else
				spawn({ 'dunstctl', 'set-paused', 'false' })
			end
		end
	end)
end

return signals
