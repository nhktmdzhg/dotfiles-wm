---@diagnostic disable: undefined-global
-- Lockscreen: per-screen lock UI, PAM authentication and keyboard grab.

---@diagnostic disable: undefined-field
local awful = require('awful')
local gears = require('gears')
local images = require('images')
local mocha = require('mocha')
-- liblua_pam lives outside Lua's default search path.
package.cpath = package.cpath .. ';/usr/lib/lua-pam/?.so'
local naughty = require('naughty')
local notifications = require('config.notifications')
local pam = require('liblua_pam')
local vars = require('config.vars')
local wibox = require('wibox')

-- Present while a lock is up; lock.sh polls it and xss-lock treats the locker's
-- exit as "unlocked". Lives in the per-user runtime dir, like the sleep fd.
local FLAG_PATH = (os.getenv('XDG_RUNTIME_DIR') or '/tmp') .. '/awesome-lockscreen.lock'

-- A flag left behind by a crash would make the next lock.sh wait forever.
os.remove(FLAG_PATH)

local lockscreen = {
	visible = false,
	password = '',
	keygrabber = nil,
	-- screen -> { ui = wibox, indicator = widget, status = widget, geometry = table }
	screens = {},
	-- Set when a lock UI is dropped so the next timer tick can reclaim it.
	dropped = false,
}

local mocha_colors = {
	mocha.rosewater.hex,
	mocha.flamingo.hex,
	mocha.pink.hex,
	mocha.mauve.hex,
	mocha.red.hex,
	mocha.maroon.hex,
	mocha.peach.hex,
	mocha.yellow.hex,
	mocha.green.hex,
	mocha.teal.hex,
	mocha.sky.hex,
	mocha.sapphire.hex,
	mocha.blue.hex,
	mocha.lavender.hex,
}

-- Reuse the scaled wallpaper between locks instead of decoding the 4K source again.
local scaled_wallpapers = {}

--- Builds the lock UI of one screen: wallpaper, clock, date, user label, indicator and status.
-- @param s screen Screen to cover.
-- @return wibox The lock wibox of that screen.
-- @return wibox.widget The indicator widget, recolored on every key press.
-- @return wibox.widget The status message widget.
local function create_lockscreen_ui(s)
	-- Main container with wallpaper
	local lock_container = wibox({
		screen = s,
		visible = false,
		ontop = true,
		type = 'splash',
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
		bg = mocha.base.hex,
	})

	-- Wallpaper widget
	local wallpaper_widget = nil
	if gears.filesystem.file_readable(vars.wallpaper) then
		local key = s.geometry.width .. 'x' .. s.geometry.height
		local surface = scaled_wallpapers[key]
			or images.scaled(vars.wallpaper, s.geometry.width, s.geometry.height)

		-- images.scaled returns nil when the file cannot be decoded.
		if surface then
			scaled_wallpapers[key] = surface
			wallpaper_widget = wibox.widget({
				image = surface,
				resize = true,
				widget = wibox.widget.imagebox,
			})
		end
	end

	-- Clock widget
	local clock_widget = wibox.widget({
		format = '<span foreground="' .. mocha.text.hex .. '">%H:%M</span>',
		font = 'Maple Mono NF CN 48',
		halign = 'center',
		widget = wibox.widget.textclock,
	})

	-- Date widget
	local date_widget = wibox.widget({
		format = '<span foreground="' .. mocha.subtext1.hex .. '">%Y年%m月%d日</span>',
		font = 'Maple Mono NF CN 16',
		halign = 'center',
		widget = wibox.widget.textclock,
	})

	-- User label
	local user_label = wibox.widget({
		markup = '<span foreground="' .. mocha.lavender.hex .. '">' .. (os.getenv('USER') or 'user') .. '</span>',
		font = 'Maple Mono NF CN 20',
		halign = 'center',
		widget = wibox.widget.textbox,
	})

	local indicator_color = mocha.surface1.hex
	local indicator_widget = wibox.widget({
		{
			{
				text = '',
				font = 'Symbols Nerd Font 40',
				halign = 'center',
				widget = wibox.widget.textbox,
			},
			id = 'lock_icon',
			widget = wibox.container.place,
		},
		bg = indicator_color,
		shape = gears.shape.circle,
		forced_width = 100,
		forced_height = 100,
		id = 'indicator_bg',
		widget = wibox.container.background,
	})

	-- Status message
	local status_message = wibox.widget({
		markup = '',
		font = 'Maple Mono NF CN 12',
		halign = 'center',
		widget = wibox.widget.textbox,
	})

	-- Container for the whole lock UI with semi-transparent background
	local ui_container = wibox.widget({
		{
			clock_widget,
			date_widget,
			{
				height = 50,
				widget = wibox.container.background,
			},
			user_label,
			{
				height = 30,
				widget = wibox.container.background,
			},
			indicator_widget,
			{
				height = 20,
				widget = wibox.container.background,
			},
			status_message,
			layout = wibox.layout.fixed.vertical,
		},
		bg = mocha.base.hex .. 'cc',
		shape = function(cr, w, h)
			gears.shape.rounded_rect(cr, w, h, 20)
		end,
		widget = wibox.container.background,
	})

	if wallpaper_widget then
		lock_container:setup({
			{
				wallpaper_widget,
				valign = 'center',
				halign = 'center',
				widget = wibox.container.place,
			},
			{
				{
					ui_container,
					left = 50,
					right = 50,
					top = 50,
					bottom = 50,
					widget = wibox.container.margin,
				},
				valign = 'center',
				halign = 'center',
				widget = wibox.container.place,
			},
			layout = wibox.layout.stack,
		})
	else
		lock_container:setup({
			{
				{
					ui_container,
					left = 50,
					right = 50,
					top = 50,
					bottom = 50,
					widget = wibox.container.margin,
				},
				valign = 'center',
				halign = 'center',
				widget = wibox.container.place,
			},
			widget = wibox.container.background,
			bg = mocha.base.hex,
		})
	end

	return lock_container, indicator_widget, status_message
end

--- Checks a password against PAM for the current user.
-- @param password string Password typed by the user.
-- @return boolean|nil True on success, false on a PAM error, nil when pam exposes no auth function.
local function authenticate(password)
	if not pam then
		naughty.notification({
			title = 'Cannot load PAM module',
			urgency = 'critical',
		})
		return true
	end

	if pam.auth_current_user then
		local ok, result = pcall(function()
			return pam.auth_current_user(password)
		end)

		if not ok then
			naughty.notification({
				title = 'PAM Error',
				urgency = 'critical',
			})
			return false
		end

		return result
	end
end

--- Applies a message to every lock UI.
-- @param message string Text to display.
-- @param is_error boolean Paint it red instead of green.
local function update_status(message, is_error)
	local color = is_error and mocha.red.hex or mocha.green.hex
	local markup = '<span foreground="' .. color .. '">' .. message .. '</span>'

	for _, entry in pairs(lockscreen.screens) do
		entry.status.markup = markup
	end
end

--- Recolors every lock indicator so a key press shows up on all screens.
local function cycle_indicator()
	for _, entry in pairs(lockscreen.screens) do
		local widget = entry.indicator
		local color = mocha_colors[math.random(#mocha_colors)]

		while color == widget.fg do
			color = mocha_colors[math.random(#mocha_colors)]
		end

		widget.fg = color
	end
end

--- Covers one screen with a lock UI and registers it.
-- @param s screen Screen to cover.
local function cover_screen(s)
	local geometry = s.geometry

	if lockscreen.screens[s] or not geometry or geometry.width <= 0 or geometry.height <= 0 then
		return
	end

	local ui, indicator, status = create_lockscreen_ui(s)

	lockscreen.screens[s] = {
		ui = ui,
		indicator = indicator,
		status = status,
		geometry = {
			x = geometry.x,
			y = geometry.y,
			width = geometry.width,
			height = geometry.height,
		},
	}

	ui.visible = true
end

--- Unmaps and forgets the lock UI of one screen.
-- @param s screen Screen whose lock UI is dropped.
local function uncover_screen(s)
	local entry = lockscreen.screens[s]

	if not entry then
		return
	end

	lockscreen.screens[s] = nil
	lockscreen.dropped = true
	entry.ui.visible = false
	entry.ui = nil
end

--- Makes the set of lock UIs match the screens that currently exist.
local function sync_screens()
	if not lockscreen.visible then
		return
	end

	local present = {}

	for s in screen do
		present[s] = true

		local entry = lockscreen.screens[s]
		local geometry = s.geometry

		if entry and geometry
			and (entry.geometry.x ~= geometry.x
				or entry.geometry.y ~= geometry.y
				or entry.geometry.width ~= geometry.width
				or entry.geometry.height ~= geometry.height) then
			uncover_screen(s)
			entry = nil
		end

		if not entry then
			cover_screen(s)
		elseif not entry.ui.visible then
			entry.ui.visible = true
		end
	end

	-- Assigning nil to existing keys is the only mutation done while traversing.
	for s in pairs(lockscreen.screens) do
		if not present[s] then
			uncover_screen(s)
		end
	end

	if lockscreen.dropped then
		lockscreen.dropped = false
		collectgarbage('collect')
	end
end

lockscreen.sync_timer = gears.timer({
	timeout = 0.5,
	autostart = false,
	single_shot = true,
	callback = sync_screens,
})

lockscreen.watch_timer = gears.timer({
	timeout = 2,
	autostart = false,
	callback = sync_screens,
})

--- Covers a screen plugged in while the session is locked.
-- @param s screen The new screen.
local function on_screen_added(s)
	if lockscreen.visible then
		cover_screen(s)
	end
end

--- Drops the lock UI of a screen that disappeared.
-- @param s screen The removed screen.
local function on_screen_removed(s)
	uncover_screen(s)
	lockscreen.sync_timer:again()
end

--- Rebuilds lock UIs whose screen changed geometry.
local function on_screen_geometry()
	if lockscreen.visible then
		lockscreen.sync_timer:again()
	end
end

--- Tells whether the lockscreen owns the keyboard grab.
-- @return boolean
local function holding_grab()
	return lockscreen.keygrabber ~= nil
		and awful.keygrabber.current_instance == lockscreen.keygrabber
end

--- Authenticates the typed password and either unlocks or clears it.
local function try_unlock()
	if #lockscreen.password == 0 then
		return
	end

	update_status('Unlocking btw...', false)

	if authenticate(lockscreen.password) then
		lockscreen.hide()
	else
		lockscreen.password = ''
		cycle_indicator()
		update_status('Failure! You are not btw.', true)
	end
end

--- Creates the keygrabber once; it is reused for every lock.
local function ensure_keygrabber()
	if lockscreen.keygrabber then
		return
	end

	lockscreen.keygrabber = awful.keygrabber({
		autostart = false,
		stop_key = nil,
		stop_event = nil,
		keypressed_callback = function(self, modifiers, key, event)
			if key == 'Return' or key == 'KP_Enter' then
				try_unlock()
			elseif key == 'BackSpace' then
				if #lockscreen.password > 0 then
					lockscreen.password = lockscreen.password:sub(1, -2)
					cycle_indicator()
				end
			elseif #key == 1 then
				lockscreen.password = lockscreen.password .. key
				cycle_indicator()
			end
		end,
		stop_callback = function(self)
			naughty.notification({
				title = 'Session Manager',
				message = 'Welcome back ' .. os.getenv('USER'),
				app_icon = 'im-user-online',
			})
			awful.spawn({ 'physlock', '-L' })
		end,
		start_callback = function(self)
			awful.spawn({ 'physlock', '-l' })
		end,
	})
end

--- Restores the notification pause state from the user flag and fullscreen state.
local function restore_notifications()
	local focused = client.focus

	if notifications.is_paused() or (focused and focused.fullscreen) then
		notifications.pause()
	else
		notifications.unpause()
	end
end

--- Covers every screen, grabs the keyboard and flags the lock for lock.sh.
-- @return boolean True when the session is locked.
function lockscreen.show()
	if lockscreen.visible then
		return true
	end

	lockscreen.password = ''
	ensure_keygrabber()

	if awful.keygrabber.current_instance then
		awful.keygrabber.current_instance:stop()
	end
	lockscreen.keygrabber:start()
	if not holding_grab() then
		return false
	end

	lockscreen.visible = true

	screen.connect_signal('added', on_screen_added)
	screen.connect_signal('removed', on_screen_removed)
	screen.connect_signal('property::geometry', on_screen_geometry)

	notifications.pause()

	local ok, err = pcall(sync_screens)
	if not ok then
		lockscreen.hide()
		error(err, 0)
	end

	local flag = io.open(FLAG_PATH, 'w')
	if flag then
		flag:close()
	end

	lockscreen.watch_timer:start()

	return true
end

--- Removes every lock UI, stops the keyboard grab and clears the typed password.
function lockscreen.hide()
	if not lockscreen.visible then
		return
	end

	lockscreen.visible = false

	lockscreen.watch_timer:stop()
	lockscreen.sync_timer:stop()

	screen.disconnect_signal('added', on_screen_added)
	screen.disconnect_signal('removed', on_screen_removed)
	screen.disconnect_signal('property::geometry', on_screen_geometry)

	restore_notifications()

	if holding_grab() then
		lockscreen.keygrabber:stop()
	end

	for s in pairs(lockscreen.screens) do
		uncover_screen(s)
	end

	lockscreen.password = ''
	lockscreen.dropped = false
	os.remove(FLAG_PATH)

	collectgarbage('collect')
end

return lockscreen
