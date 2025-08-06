local button = require('awful.button')
local key = require('awful.key')
local screen = require('awful.screen')
local scripts = require('scripts')
local signals = require('config.signals')
local spawn = require('awful.spawn')

local keys = {}

local function toggle_show_desktop()
	local current_tag = screen.focused().selected_tag
	local client_on_tag = current_tag:clients()
	if #client_on_tag > 0 then
		local is_show = false
		for _, c in ipairs(client_on_tag) do
			if c:isvisible() then
				is_show = true
				break
			end
		end
		if is_show then
			for _, c in ipairs(client_on_tag) do
				if c:isvisible() then
					c.minimized = true
				end
			end
		else
			for _, c in ipairs(client_on_tag) do
				if not c:isvisible() then
					c.minimized = false
				end
			end
		end
	end
end

function keys.init(vars)
	local super = vars.super
	local alt = vars.alt
	local ctrl = vars.ctrl
	local shift = vars.shift
	local home = vars.home
	local margin_top = vars.margin_top
	local margin_bottom = vars.margin_bottom
	local margin_left = vars.margin_left
	local margin_right = vars.margin_right

	local switcher = require('awesome-switcher')

	local globalkeys = { -- Brightness controls --
		key({}, 'XF86MonBrightnessUp', function()
			scripts.change_brightness(1)
		end),
		key({}, 'XF86MonBrightnessDown', function()
			scripts.change_brightness(-1)
		end), -- Audio-volume controls --
		key({}, 'XF86AudioRaiseVolume', function()
			scripts.get_volume_info(1, nil)
		end),
		key({}, 'XF86AudioLowerVolume', function()
			scripts.get_volume_info(-1, nil)
		end),
		key({}, 'XF86AudioMute', function()
			scripts.get_volume_info(0, nil)
		end),
		key({}, 'XF86AudioPlay', function()
			spawn({ 'playerctl', 'play-pause' })
		end),
		key({}, 'XF86AudioNext', function()
			spawn({ 'playerctl', 'next' })
		end),
		key({}, 'XF86AudioPrev', function()
			spawn({ 'playerctl', 'previous' })
		end),
		key({}, 'XF86AudioStop', function()
			spawn({ 'playerctl', 'play-pause' })
		end),
		key({}, 'XF86AudioPause', function()
			spawn({ 'playerctl', 'play-pause' })
		end), -- Window controls --
		key({ alt }, 'Tab', function()
			switcher.switch(1, alt, 'Alt_L', shift, 'Tab')
		end),
		key({ alt, shift }, 'Tab', function()
			switcher.switch(-1, alt, 'Alt_L', shift, 'Tab')
		end), -- Menu controls --
		key({ super }, 'Escape', function()
			spawn('wlogout')
		end),
		key({ alt }, 'F2', function()
			spawn({ 'env', 'XMODIFIERS=@im=none', 'rofi', '-no-lazy-grab', '-show', 'drun' })
		end), -- Screenshot controls --
		key({ ctrl }, 'Print', function()
			spawn({ 'flameshot', 'gui' })
		end),
		key({}, 'Print', function()
			spawn({ 'flameshot', 'full' })
		end), -- Applications --
		key({ super }, 'e', function()
			spawn('thunar')
		end),
		key({ super }, 'l', function()
			spawn({ home .. '/.config/awesome/xss-lock-tsl.sh' })
		end),
		key({ ctrl, alt }, 't', function()
			spawn({ 'wezterm' })
		end),
		key({ ctrl, shift }, 'Escape', function()
			spawn({ 'wezterm', '-e', 'btm' })
		end), -- Awesome --
		key({ super, ctrl }, 'r', awesome.restart),
		key({ super }, 'd', toggle_show_desktop),
		key({ super }, 'b', function()
			spawn('zen-browser')
		end),
		key({ super }, 'n', function()
			spawn('goneovim')
		end),
		key({ super }, 'c', function()
			spawn('legcord')
		end),
		-- Dunst toggle --
		key({ super, ctrl }, 'n', function()
			signals.toggle_dunst()
		end),
	}

	local clientkeys = {
		key({ super, shift }, 'Up', function(c)
			c:relative_move(0, -10, 0, 0)
		end),
		key({ super, shift }, 'Down', function(c)
			c:relative_move(0, 10, 0, 0)
		end),
		key({ super, shift }, 'Left', function(c)
			c:relative_move(-10, 0, 0, 0)
		end),
		key({ super, shift }, 'Right', function(c)
			c:relative_move(10, 0, 0, 0)
		end),
		key({ super }, 'Up', function(c)
			local wa = c.screen.workarea
			c:geometry({
				x = wa.x + margin_left,
				y = wa.y + margin_top,
				width = wa.width - margin_left - margin_right,
				height = (wa.height - margin_top - margin_bottom) / 2,
			})
		end),
		key({ super }, 'Down', function(c)
			local wa = c.screen.workarea
			local height = (wa.height - margin_top - margin_bottom) / 2
			c:geometry({
				x = wa.x + margin_left,
				y = wa.y + margin_top + height,
				width = wa.width - margin_left - margin_right,
				height = height,
			})
		end),
		key({ super }, 'Left', function(c)
			local wa = c.screen.workarea
			c:geometry({
				x = wa.x + margin_left,
				y = wa.y + margin_top,
				width = (wa.width - margin_left - margin_right) / 2,
				height = wa.height - margin_top - margin_bottom,
			})
		end),
		key({ super }, 'Right', function(c)
			local wa = c.screen.workarea
			local width = (wa.width - margin_left - margin_right) / 2
			c:geometry({
				x = wa.x + margin_left + width,
				y = wa.y + margin_top,
				width = width,
				height = wa.height - margin_top - margin_bottom,
			})
		end), -- Window controls --
		key({ alt }, 'F4', function(c)
			c:kill()
		end),
		key({ super }, 'f', function(c)
			c.fullscreen = not c.fullscreen
		end),
		key({ super }, 'x', function(c)
			c.maximized = not c.maximized
		end),
		key({ super }, 'z', function(c)
			c.minimized = true
			c:lower()
		end),
	}

	local clientbuttons = {
		button({}, 1, function(c)
			c:activate({ context = 'mouse_click' })
		end),
		button({ super }, 1, function(c)
			c:activate({ context = 'mouse_click', action = 'mouse_move' })
		end),
		button({ super }, 3, function(c)
			c:activate({ context = 'mouse_click', action = 'mouse_resize' })
		end),
	}

	return {
		globalkeys = globalkeys,
		clientkeys = clientkeys,
		clientbuttons = clientbuttons,
	}
end

return keys
