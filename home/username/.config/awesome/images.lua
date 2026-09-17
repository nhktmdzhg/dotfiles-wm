local cairo = require('lgi').cairo
local gears = require('gears')

local images = {}

--- Loads an image file into a new surface, scaled down to fit the given box.
-- @param path string Image file path.
-- @param max_width number Maximum width of the returned surface.
-- @param max_height number Maximum height of the returned surface.
-- @return cairo.Surface|nil The scaled surface, nil when the image cannot be loaded.
function images.scaled(path, max_width, max_height)
	local source = gears.surface.load_uncached(path)

	if not source then
		return nil
	end

	local ok, width, height = pcall(gears.surface.get_size, source)
	if not ok or width == 0 or height == 0 then
		return nil
	end

	local scale = math.min(1, max_width / width, max_height / height)
	local scaled_width = math.max(1, math.floor(width * scale + 0.5))
	local scaled_height = math.max(1, math.floor(height * scale + 0.5))
	local scaled = cairo.ImageSurface(cairo.Format.RGB24, scaled_width, scaled_height)
	local cr = cairo.Context(scaled)

	cr:scale(scale, scale)
	cr:set_source_surface(source, 0, 0)
	cr:paint()

	return scaled
end

return images
