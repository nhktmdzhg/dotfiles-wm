---@diagnostic disable: undefined-global
-- Core libraries
local cairo = require('lgi').cairo
local awful = require('awful')
local gears = require('gears')
local palette = require('mocha')
local wibox = require('wibox')

-- Import keygrabber properly
local keygrabber = awful.keygrabber

-- Import globals properly
local table = table
local math = require('math')
local string = string
local debug = debug
local pairs = pairs

-- Pre-compute frequently used values
local timer = gears.timer
awful.client = require('awful.client')

-- Cache surface creation (these don't need to be recreated every time)
local surface = cairo.ImageSurface(cairo.Format.RGB24, 20, 20)
local cr = cairo.Context(surface)

-- Pre-compute colors for better performance
local text_color_normalized = {
	palette.text.rgb[1] / 255,
	palette.text.rgb[2] / 255,
	palette.text.rgb[3] / 255,
	1,
}

local _M = {}

-- Hard-coded optimized values (removed settings table for better performance)
local PREVIEW_BOX_BG = palette.surface0.hex .. 'ee'
local PREVIEW_BOX_BORDER = palette.base.hex .. '00'
local PREVIEW_BOX_FPS = 60
local PREVIEW_BOX_DELAY = 150
local PREVIEW_BOX_TITLE_FONT = { 'sans', 'italic', 'normal' }
local PREVIEW_BOX_TITLE_FONT_SIZE_FACTOR = 0.8
local PREVIEW_BOX_TITLE_COLOR = text_color_normalized
local CYCLE_ALL_CLIENTS = false
local icon_dir = os.getenv('HOME') .. '/.local/share/icons/BeautyLine/apps/scalable/'

-- Create wibox with optimized settings
_M.preview_wbox = wibox({
	width = screen[mouse.screen].geometry.width,
	border_width = 0,
	ontop = true,
	visible = false,
})

-- Use more efficient timer creation with hard-coded FPS
_M.preview_live_timer = timer({
	timeout = 1 / PREVIEW_BOX_FPS,
})
_M.preview_widgets = {}

_M.altTabTable = {}
_M.altTabIndex = 1

_M.source = string.sub(debug.getinfo(1, 'S').source, 2)
_M.path = string.sub(_M.source, 1, string.find(_M.source, '/[^/]*$'))
_M.noicon = _M.path .. 'noicon.svg'

-- Optimized function for counting table size (use # operator when possible)
function _M.tableLength(T)
	-- For array-like tables, use the # operator which is much faster
	local length = #T
	if length > 0 then
		return length
	end

	-- For hash tables, fall back to manual counting
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

-- Optimized function to get clients list
function _M.getClients()
	local clients = {}
	local client_set = {} -- Hash table for O(1) lookup instead of O(n) array search

	-- Get focus history for current tag
	local s = mouse.screen
	local idx = 0
	local c = awful.client.focus.history.get(s, idx)

	-- Add clients from focus history
	while c do
		clients[#clients + 1] = c -- Faster than table.insert
		client_set[c] = true -- Mark as added

		idx = idx + 1
		c = awful.client.focus.history.get(s, idx)
	end

	-- Add minimized clients not in focus history
	local t = s.selected_tag
	local all = client.get(s)

	for i = 1, #all do
		c = all[i]

		-- Skip if already added
		if not client_set[c] then
			local ctags = c:tags()
			local isCurrentTag = false

			-- Check if client is on current tag
			for j = 1, #ctags do
				if t == ctags[j] then
					isCurrentTag = true
					break -- Early exit when found
				end
			end

			if isCurrentTag or CYCLE_ALL_CLIENTS then
				clients[#clients + 1] = c
				client_set[c] = true
			end
		end
	end

	return clients
end

-- Optimized function to populate alt-tab table
function _M.populateAltTabTable()
	local clients = _M.getClients()

	-- If we have existing data, restore minimized states efficiently
	if #_M.altTabTable > 0 then
		-- Create hash map for O(1) lookup instead of nested loops
		local old_client_states = {}
		for i = 1, #_M.altTabTable do
			local entry = _M.altTabTable[i]
			old_client_states[entry.client] = entry.minimized
		end

		-- Restore states
		for i = 1, #clients do
			local c = clients[i]
			local old_state = old_client_states[c]
			if old_state ~= nil then
				c.minimized = old_state
			end
		end
	end

	-- Clear and rebuild table efficiently
	_M.altTabTable = {}

	for i = 1, #clients do
		_M.altTabTable[i] = {
			client = clients[i],
			minimized = clients[i].minimized,
		}
	end
end

-- If the length of list of clients is not equal to the length of altTabTable,
-- we need to repopulate the array and update the UI. This function does this
-- check.
function _M.clientsHaveChanged()
	local clients = _M.getClients()
	return _M.tableLength(clients) ~= _M.tableLength(_M.altTabTable)
end

function _M.createPreviewText(c)
	if c.class then
		return ' - ' .. c.class
	else
		return ' - ' .. c.name
	end
end

-- Preview is created here.
-- This is called any _M.settings.preview_box_fps milliseconds. In case the list
-- of clients is changed, we need to redraw the whole preview box. Otherwise, a
-- simple widget::updated signal is enough
function _M.updatePreview()
	if _M.clientsHaveChanged() then
		_M.populateAltTabTable()
		_M.preview()
	end

	for i = 1, #_M.preview_widgets do
		_M.preview_widgets[i]:emit_signal('widget::updated')
	end
end

function _M.cycle(dir)
	-- Switch to next client
	_M.altTabIndex = (_M.altTabIndex + dir) % #_M.altTabTable
	if _M.altTabIndex == 0 then
		_M.altTabIndex = #_M.altTabTable
	end

	_M.updatePreview()
	_M.altTabTable[_M.altTabIndex].client.minimized = false
end

function _M.preview()
	-- Apply hard-coded settings for better performance
	_M.preview_wbox:set_bg(PREVIEW_BOX_BG)
	_M.preview_wbox.border_color = PREVIEW_BOX_BORDER

	-- Make the wibox the right size, based on the number of clients
	local n = math.max(7, #_M.altTabTable)
	local W = screen[mouse.screen].geometry.width -- + 2 * _M.preview_wbox.border_width
	local w = W / n -- widget width
	local h = w * 0.75 -- widget height
	local textboxHeight = w * 0.125

	local x = screen[mouse.screen].geometry.x - _M.preview_wbox.border_width
	local y = screen[mouse.screen].geometry.y + (screen[mouse.screen].geometry.height - h - textboxHeight) / 2
	_M.preview_wbox:geometry({
		x = x,
		y = y,
		width = W,
		height = h + textboxHeight,
	})

	-- create a list that holds the clients to preview, from left to right
	local leftRightTab = {}
	local leftRightTabToAltTabIndex = {} -- save mapping from leftRightTab to altTabTable as well
	local nLeft
	local nRight
	if #_M.altTabTable == 2 then
		nLeft = 0
		nRight = 2
	else
		nLeft = math.floor(#_M.altTabTable / 2)
		nRight = math.ceil(#_M.altTabTable / 2)
	end

	for i = 1, nLeft do
		table.insert(leftRightTab, _M.altTabTable[#_M.altTabTable - nLeft + i].client)
		table.insert(leftRightTabToAltTabIndex, #_M.altTabTable - nLeft + i)
	end
	for i = 1, nRight do
		table.insert(leftRightTab, _M.altTabTable[i].client)
		table.insert(leftRightTabToAltTabIndex, i)
	end

	-- determine fontsize -> find maximum classname-length
	local text, textWidth, textHeight, maxText
	local maxTextWidth = 0
	local maxTextHeight = 0
	local bigFont = textboxHeight / 2
	cr:set_font_size(bigFont)
	for i = 1, #leftRightTab do
		text = _M.createPreviewText(leftRightTab[i])
		textWidth = cr:text_extents(text).width
		textHeight = cr:text_extents(text).height
		if textWidth > maxTextWidth or textHeight > maxTextHeight then
			maxTextHeight = textHeight
			maxTextWidth = textWidth
			maxText = text
		end
	end

	while true do
		cr:set_font_size(bigFont)
		textWidth = cr:text_extents(maxText).width
		textHeight = cr:text_extents(maxText).height

		if textWidth < w - textboxHeight and textHeight < textboxHeight then
			break
		end

		bigFont = bigFont - 1
	end
	local smallFont = bigFont * PREVIEW_BOX_TITLE_FONT_SIZE_FACTOR

	_M.preview_widgets = {}

	-- create all the widgets
	for i = 1, #leftRightTab do
		_M.preview_widgets[i] = wibox.widget.base.make_widget()
		_M.preview_widgets[i].fit = function(_, _, _)
			return w, h
		end
		local c = leftRightTab[i]
		_M.preview_widgets[i].draw = function(_, _, cairo_context, width, height)
			if width ~= 0 and height ~= 0 then
				local a = 0.8
				local overlay = 0.6
				local fontSize = smallFont
				if c == _M.altTabTable[_M.altTabIndex].client then
					a = 0.9
					overlay = 0
					fontSize = bigFont
				end

				local sx, sy, tx, ty

				-- Icons
				local icon
				local icon_path = icon_dir .. string.lower(c.class) .. '.svg'
				if gears.filesystem.file_readable(icon_path) then
					icon = gears.surface(gears.surface.load(icon_path))
				elseif c.icon then
					icon = gears.surface(c.icon)
				else
					if c.class == 'legcord' then
						icon = gears.surface(gears.surface.load(icon_dir .. 'discord.svg'))
					elseif c.class == 'Zalo' then
						icon = gears.surface(gears.surface.load('/opt/zalo/icon.png'))
					else
						icon = gears.surface(gears.surface.load(_M.noicon))
					end
				end

				local iconboxWidth = 0.9 * textboxHeight
				local iconboxHeight = iconboxWidth

				-- Titles
				cairo_context:select_font_face(
					PREVIEW_BOX_TITLE_FONT[1],
					PREVIEW_BOX_TITLE_FONT[2],
					PREVIEW_BOX_TITLE_FONT[3]
				)
				cairo_context:set_font_face(cairo_context:get_font_face())
				cairo_context:set_font_size(fontSize)

				text = _M.createPreviewText(c)
				textWidth = cairo_context:text_extents(text).width
				textHeight = cairo_context:text_extents(text).height

				local titleboxWidth = textWidth + iconboxWidth

				-- Draw icons
				tx = (w - titleboxWidth) / 2
				ty = h
				sx = iconboxWidth / icon.width
				sy = iconboxHeight / icon.height

				cairo_context:translate(tx, ty)
				cairo_context:scale(sx, sy)
				cairo_context:set_source_surface(icon, 0, 0)
				cairo_context:paint()
				cairo_context:scale(1 / sx, 1 / sy)
				cairo_context:translate(-tx, -ty)

				-- Draw titles
				tx = tx + iconboxWidth
				ty = h + (textboxHeight + textHeight) / 2

				cairo_context:set_source_rgba(
					PREVIEW_BOX_TITLE_COLOR[1],
					PREVIEW_BOX_TITLE_COLOR[2],
					PREVIEW_BOX_TITLE_COLOR[3],
					PREVIEW_BOX_TITLE_COLOR[4]
				)
				cairo_context:move_to(tx, ty)
				cairo_context:show_text(text)
				cairo_context:stroke()

				-- Draw previews
				local cg = c:geometry()
				if cg.width > cg.height then
					sx = a * w / cg.width
					sy = math.min(sx, a * h / cg.height)
				else
					sy = a * h / cg.height
					sx = math.min(sy, a * h / cg.width)
				end

				tx = (w - sx * cg.width) / 2
				ty = (h - sy * cg.height) / 2

				local tmp = gears.surface(c.content)
				cairo_context:translate(tx, ty)
				cairo_context:scale(sx, sy)
				cairo_context:set_source_surface(tmp, 0, 0)
				cairo_context:paint()
				tmp:finish()

				-- Overlays
				cairo_context:scale(1 / sx, 1 / sy)
				cairo_context:translate(-tx, -ty)
				cairo_context:set_source_rgba(0, 0, 0, overlay)
				cairo_context:rectangle(tx, ty, sx * cg.width, sy * cg.height)
				cairo_context:fill()
			end
		end

		-- Add mouse handler
		_M.preview_widgets[i]:connect_signal('mouse::enter', function()
			_M.cycle(leftRightTabToAltTabIndex[i] - _M.altTabIndex)
		end)
	end

	-- Spacers left and right
	local spacer = wibox.widget.base.make_widget()
	spacer.fit = function(_, _, _)
		return (W - w * #_M.altTabTable) / 2, _M.preview_wbox.height
	end
	spacer.draw = function(_, _, _, _, _)
		-- Draw nothing, just a spacer
	end

	-- layout
	local preview_layout = wibox.layout.fixed.horizontal()

	preview_layout:add(spacer)
	for i = 1, #leftRightTab do
		preview_layout:add(_M.preview_widgets[i])
	end
	preview_layout:add(spacer)

	_M.preview_wbox:set_widget(preview_layout)
end

-- This starts the timer for updating and it shows the preview UI.
function _M.showPreview()
	_M.preview_live_timer.timeout = 1 / PREVIEW_BOX_FPS
	_M.preview_live_timer:connect_signal('timeout', _M.updatePreview)
	_M.preview_live_timer:start()

	_M.preview()
	_M.preview_wbox.visible = true
end

function _M.switch(dir, mod_key1, release_key, mod_key2, key_switch)
	_M.populateAltTabTable()

	if #_M.altTabTable == 0 then
		return
	elseif #_M.altTabTable == 1 then
		_M.altTabTable[1].client.minimized = false
		_M.altTabTable[1].client:raise()
		return
	end

	-- reset index
	_M.altTabIndex = 1

	-- preview delay timer
	local previewDelay = PREVIEW_BOX_DELAY / 1000
	_M.previewDelayTimer = timer({
		timeout = previewDelay,
	})
	_M.previewDelayTimer:connect_signal('timeout', function()
		_M.previewDelayTimer:stop()
		_M.showPreview()
	end)
	_M.previewDelayTimer:start()

	-- Now that we have collected all windows, we should run a keygrabber
	-- as long as the user is alt-tabbing:
	keygrabber.run(function(mod, key, event)
		-- Stop alt-tabbing when the alt-key is released
		if gears.table.hasitem(mod, mod_key1) then
			if (key == release_key or key == 'Escape') and event == 'release' then
				if _M.preview_wbox.visible == true then
					_M.preview_wbox.visible = false
					_M.preview_live_timer:stop()
				else
					_M.previewDelayTimer:stop()
				end

				if key == 'Escape' then
					for i = 1, #_M.altTabTable do
						_M.altTabTable[i].client.minimized = _M.altTabTable[i].minimized
					end
				else
					-- Raise clients in order to restore history
					local c
					for i = 1, _M.altTabIndex - 1 do
						c = _M.altTabTable[_M.altTabIndex - i].client
						if not _M.altTabTable[i].minimized then
							c:raise()
							client.focus = c
						end
					end

					-- raise chosen client on top of all
					c = _M.altTabTable[_M.altTabIndex].client
					c:raise()
					c:jump_to()
					client.focus = c

					-- restore minimized clients
					for i = 1, #_M.altTabTable do
						if i ~= _M.altTabIndex and _M.altTabTable[i].minimized then
							_M.altTabTable[i].client.minimized = true
						end
					end
				end

				keygrabber.stop()
			elseif key == key_switch and event == 'press' then
				if gears.table.hasitem(mod, mod_key2) then
					-- Move to previous client on Shift-Tab
					_M.cycle(-1)
				else
					-- Move to next client on each Tab-press
					_M.cycle(1)
				end
			end
		end
	end)

	-- switch to next client
	_M.cycle(dir)
end -- function altTab

return {
	switch = _M.switch,
}
