---@diagnostic disable: undefined-field
local awful = require('awful')
local gears = require('gears')
local mocha = require('mocha')
local pam = require('liblua_pam')
local vars = require('config.vars')
local wibox = require('wibox')

local lockscreen = {
	visible = false,
	screen_lock = nil,
	password_widget = nil,
	keygrabber = nil,
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
		wallpaper_widget = wibox.widget({
			image = vars.wallpaper,
			resize = true,
			widget = wibox.widget.imagebox,
		})
	end

	-- Clock widget
	local clock_widget = wibox.widget({
		format = '<span foreground="' .. mocha.text.hex .. '">%H:%M</span>',
		font = 'Maple Mono NF CN 48',
		align = 'center',
		widget = wibox.widget.textclock,
	})

	-- Date widget
	local date_widget = wibox.widget({
		format = '<span foreground="' .. mocha.subtext1.hex .. '">%Y年%m月%d日</span>',
		font = 'Maple Mono NF CN 16',
		align = 'center',
		widget = wibox.widget.textclock,
	})

	-- User label
	local user_label = wibox.widget({
		markup = '<span foreground="' .. mocha.lavender.hex .. '">' .. (os.getenv('USER') or 'user') .. '</span>',
		font = 'Maple Mono NF CN 20',
		align = 'center',
		widget = wibox.widget.textbox,
	})

	local indicator_color = mocha.surface1.hex
	local indicator_widget = wibox.widget({
		{
			{
				text = '',
				font = 'JetBrainsMono Nerd Font Mono 48',
				align = 'center',
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
		align = 'center',
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

local function authenticate(password)
	if not pam then
		awful.spawn({ 'notify-send', 'Cannot load PAM module', '-u', 'critical' })
		return true
	end

	if pam.auth_current_user then
		local ok, result = pcall(function()
			return pam.auth_current_user(password)
		end)

		if not ok then
			awful.spawn({ 'notify-send', 'PAM Error', '-u', 'critical' })
			return false
		end

		return result
	end
end

function lockscreen.show()
	if lockscreen.visible then
		return
	end

	lockscreen.visible = true

	-- Store current screen
	local current_screen = awful.screen.focused()

	-- Create lockscreen for each screen
	lockscreen.screens = {}
	lockscreen.password = ''

	---@diagnostic disable-next-line: undefined-global
	for s in screen do
		local lock_ui, indicator_widget, status_widget = create_lockscreen_ui(s)
		lock_ui.visible = true

		table.insert(lockscreen.screens, {
			ui = lock_ui,
			indicator_widget = indicator_widget,
			status_widget = status_widget,
		})

		if s == current_screen then
			lockscreen.main_screen = #lockscreen.screens
		end
	end

	local function update_status(message, is_error)
		for _, screen_lock in ipairs(lockscreen.screens) do
			if is_error then
				screen_lock.status_widget.markup = '<span foreground="' .. mocha.red.hex .. '">' .. message .. '</span>'
			else
				screen_lock.status_widget.markup = '<span foreground="'
					.. mocha.green.hex
					.. '">'
					.. message
					.. '</span>'
			end
		end
	end

	local function update_indicator()
		for _, screen_lock in ipairs(lockscreen.screens) do
			if screen_lock.indicator_widget then
				local random_color = mocha_colors[math.random(#mocha_colors)]
				while random_color == screen_lock.indicator_widget.fg do
					random_color = mocha_colors[math.random(#mocha_colors)]
				end
				screen_lock.indicator_widget.fg = random_color
			end
		end
	end

	local function try_unlock()
		update_status('Unlocking btw...', false)
		if authenticate(lockscreen.password) then
			lockscreen.hide()
		else
			lockscreen.password = ''
			update_indicator()
			update_status('Failure! You are not btw.', true)
		end
	end

	update_indicator()

	if not lockscreen.keygrabber then
		lockscreen.keygrabber = awful.keygrabber({
			autostart = false,
			keypressed_callback = function(_, _, key, _)
				if key == 'BackSpace' then
					if #lockscreen.password > 0 then
						lockscreen.password = lockscreen.password:sub(1, -2)
						update_indicator()
					end
				elseif #key == 1 then
					lockscreen.password = lockscreen.password .. key
					update_indicator()
				end
			end,
			keyreleased_callback = function(_, _, key, _)
				if key == 'Return' or key == 'KP_Enter' then
					try_unlock()
				end
			end,
			stop_callback = function()
				awful.spawn({
					'notify-send',
					'-i',
					'im-user-online',
					'Session Manager',
					'Welcome back ' .. os.getenv('USER'),
				})
				awful.spawn({ 'physlock', '-L' })
			end,
			start_callback = function()
				awful.spawn({ 'physlock', '-l' })
			end,
		})
	end
	lockscreen.keygrabber:start()
end

function lockscreen.hide()
	if not lockscreen.visible then
		return
	end

	lockscreen.visible = false
	if lockscreen.keygrabber then
		lockscreen.keygrabber:stop()
	end

	if lockscreen.screens then
		for _, screen_lock in ipairs(lockscreen.screens) do
			screen_lock.ui.visible = false
			screen_lock.ui:disconnect_signal()
			screen_lock.ui = nil
		end
		lockscreen.screens = {}
		lockscreen.screens = nil
	end

	lockscreen.password = ''
	lockscreen.main_screen = nil

	collectgarbage('collect')
end

return lockscreen
