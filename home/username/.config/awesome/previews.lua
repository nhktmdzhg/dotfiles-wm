---@diagnostic disable: undefined-global
local cairo = require('lgi').cairo
local filesystem = require('gears.filesystem')
local gears = require('gears')

local previews = {}

local THUMB_WIDTH = 320
local FRESH_SECONDS = 1
local noicon_path = filesystem.get_configuration_dir() .. 'awesome-switcher/noicon.svg'
local icon_dir = '/usr/share/icons/BeautyLine/apps/scalable/'
local cache = setmetatable({}, { __mode = 'k' })
local captured_at = setmetatable({}, { __mode = 'k' })

local function live_surface(c)
	local s = gears.surface(c.content)

	if not s then
		return nil
	end

	local ok, width, height = pcall(gears.surface.get_size, s)
	if not ok or width == 0 or height == 0 then
		return nil
	end

	return s, width, height
end

--- Copies a small thumbnail of a visible client, to be used once it is hidden.
-- @param c client Client to capture.
function previews.capture(c)
	if not c or not c.valid or not c:isvisible() then
		return
	end

	local s, width, height = live_surface(c)
	if not s then
		return
	end

	local scale = math.min(1, THUMB_WIDTH / width)
	local thumb_width = math.max(1, math.floor(width * scale + 0.5))
	local thumb_height = math.max(1, math.floor(height * scale + 0.5))
	local thumb = cairo.ImageSurface(cairo.Format.RGB24, thumb_width, thumb_height)
	local cr = cairo.Context(thumb)

	cr:scale(scale, scale)
	cr:set_source_surface(s, 0, 0)
	cr:paint()

	cache[c] = thumb
	captured_at[c] = os.time()
end

--- Returns the surface to draw for a client preview.
-- @param c client Client to preview.
-- @return cairo.Surface|nil The live content while the client is visible, otherwise the cached thumbnail.
function previews.surface(c)
	if not c or not c.valid then
		return nil
	end

	if c:isvisible() then
		local s = live_surface(c)
		if s then
			if not cache[c] then
				previews.capture(c)
			end

			return s
		end
	end

	return cache[c]
end

--- Returns the application icon of a client.
-- @param c client Client whose icon is wanted.
-- @return cairo.Surface|nil The themed icon, the client hint, or the generic noicon.
function previews.icon(c)
	if not c or not c.valid then
		return nil
	end

	local icon_path = icon_dir .. string.lower(c.class or '') .. '.svg'
	if c.class and filesystem.file_readable(icon_path) then
		return gears.surface.load(icon_path)
	end

	return gears.surface(c.icon) or gears.surface.load(noicon_path)
end

--- Drops a cached thumbnail that predates the minimize, so a stale frame is never shown.
-- @param c client Client that got minimized.
local function drop_stale_thumbnail(c)
	if not c.minimized or not cache[c] then
		return
	end

	if os.time() - (captured_at[c] or 0) > FRESH_SECONDS then
		cache[c] = nil
		captured_at[c] = nil
	end
end

client.connect_signal('property::minimized', drop_stale_thumbnail)

return previews
