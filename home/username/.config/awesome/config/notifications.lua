-- Naughty setup: pause state, notification template, urgency presets and icon lookup.

---@diagnostic disable: undefined-global
local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local naughty = require('naughty')
local palette = require('mocha')
local wibox = require('wibox')

local notifications = {}

-- Pause flag requested by the user (see toggle_naughty).
local naughty_paused = false
-- Effective pause flag, also set by fullscreen handling in config.signals.
local real_paused = false

local beautyline_base = '/usr/share/icons/BeautyLine/'
local beautyline_categories = { 'actions', 'apps', 'devices', 'mimetypes', 'places' }

--- Looks the icon up in the BeautyLine theme directories.
-- @param icon_name string Icon name to resolve.
-- @return string|nil Path of the first matching svg, nil when the theme has no such icon.
local function find_in_beautyline(icon_name)
	for _, category in ipairs(beautyline_categories) do
		local path = beautyline_base .. category .. '/scalable/' .. icon_name .. '.svg'
		if filesystem.file_readable(path) then
			return path
		end
	end

	return nil
end

--- Stops notifications from being displayed.
function notifications.pause()
	real_paused = true
end

--- Lets notifications be displayed again.
function notifications.unpause()
	real_paused = false
end

--- Flips the naughty pause flag, ignoring clients that are fullscreen.
function notifications.toggle_naughty()
	naughty_paused = not naughty_paused
	if client.focus and client.focus.fullscreen then
		return
	end
	if naughty_paused then
		notifications.pause()
	else
		notifications.unpause()
	end
end

--- Tells whether the user asked notifications to be paused.
-- @return boolean The naughty pause flag.
function notifications.is_paused()
	return naughty_paused
end

--- Connects the naughty signals and installs the urgency presets.
function notifications.init()
	-- Draw every notification with the dashboard look, unless paused.
	naughty.connect_signal('request::display', function(n)
		if real_paused then
			return
		end
		local bg = palette.base.hex
		local fg = palette.text.hex
		local border_color = palette.mantle.hex

		if n.urgency == 'critical' then
			border_color = palette.peach.hex
		end

		local original_title = n.title
		n.title = '<b>' .. original_title .. '</b>'

		naughty.layout.box({
			notification = n,
			widget_template = {
				{
					{
						{
							{
								naughty.widget.icon,
								{
									{
										naughty.widget.title,
										font = 'Maple Mono NF CN 16',
										fg = fg,
										widget = naughty.widget.title,
									},
									{
										naughty.widget.message,
										font = 'Maple Mono NF CN 13',
										fg = palette.subtext1.hex,
										widget = naughty.widget.message,
									},
									spacing = 4,
									layout = wibox.layout.fixed.vertical,
								},
								fill_space = true,
								spacing = 10,
								layout = wibox.layout.fixed.horizontal,
							},
							naughty.list.actions,
							spacing = 10,
							layout = wibox.layout.fixed.vertical,
						},
						margins = 15,
						widget = wibox.container.margin,
					},
					bg = bg,
					fg = fg,
					shape = beautiful.notification_shape,
					border_width = beautiful.notification_border_width,
					border_color = border_color,
					widget = naughty.container.background,
				},
				strategy = 'max',
				width = 400,
				widget = wibox.container.constraint,
			},
		})
	end)

	naughty.config.presets.low = {
		bg = palette.base.hex,
		fg = palette.text.hex,
		border_width = 6,
		border_color = palette.mantle.hex,
		shape = beautiful.notification_shape,
		opacity = 0.95,
		timeout = 5,
	}

	naughty.config.presets.normal = naughty.config.presets.low

	naughty.config.presets.critical = {
		bg = palette.base.hex,
		fg = palette.text.hex,
		border_width = 6,
		border_color = palette.peach.hex,
		shape = beautiful.notification_shape,
		opacity = 0.95,
		timeout = 0,
	}

	-- Resolve app icons through the BeautyLine theme first, then menubar.
	naughty.connect_signal('request::icon', function(n, context, hints)
		if context ~= 'app_icon' then
			return
		end

		local path = find_in_beautyline(hints.app_icon)
			or find_in_beautyline(hints.app_icon:lower())
			or require('menubar').utils.lookup_icon(hints.app_icon)
			or require('menubar').utils.lookup_icon(hints.app_icon:lower())

		if path then
			n.icon = path
		end
	end)

	-- Resolve action icons through the BeautyLine theme first, then menubar.
	naughty.connect_signal('request::action_icon', function(a, context, hints)
		if context ~= 'action_icon' then
			return
		end

		local path = find_in_beautyline(hints.id)
			or find_in_beautyline(hints.id:lower())
			or require('menubar').utils.lookup_icon(hints.id)
			or require('menubar').utils.lookup_icon(hints.id:lower())

		if path then
			a.icon = path
		end
	end)
end

return notifications
