--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.autopos = "center"
swayimg.viewer.loop = true
swayimg.viewer.preload = 1

local text = {
	topleft = {
		"File: {name}",
		"Format: {format}",
		"File size: {sizehr}",
		"Size: {frame.width}x{frame.height}",
		"{meta.Exif.Photo.DateTimeOriginal}",
		"{meta.Exif.Image.Model}",
	},
	topright = {
		"Image: {list.index} of {list.total}",
		"Frame: {frame.index} of {frame.total}",
		"Scale: {scale}",
	},
	bottomleft = {},
	bottomright = {},
}
swayimg.viewer.text = text

local help = {
	"Viewer keys (F1 to close)",
	"",
	help_common.wallpaper,
	help_common.copy,
	help_common.edit,
	"h / l	Previous / next image",
	help_common.first_last,
	"+ / - / wheel	Zoom",
	"c	Fit to width",
	"<	Rotate 90 degrees",
	"Return	Gallery",
	help_common.fullscreen,
	help_common.quit,
}

swayimg.on_window_resize(function()
	if swayimg.mode == "viewer" then
		swayimg.viewer.set_fix_scale("optimal")
	end
end)

local function next_image()
	swayimg.viewer.open("next")
end

local function prev_image()
	swayimg.viewer.open("prev")
end

-- Zoom around the mouse pointer by a fraction of the current scale.
local function zoom(delta)
	local mouse = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.scale
	swayimg.viewer.set_abs_scale(scale + scale * delta, mouse.x, mouse.y)
end

--------------------------------------------------------------------------------
-- Binds
--------------------------------------------------------------------------------
swayimg.viewer.on_key("F1", make_help_toggle(swayimg.viewer, text, "bottomleft", help))
bind_common(swayimg.viewer)

swayimg.viewer.on_key("<", function()
	swayimg.viewer.rotate(90)
end)

swayimg.viewer.on_key({ "Up", "l" }, next_image)
swayimg.viewer.on_key({ "Down", "h" }, prev_image)

swayimg.viewer.on_key("plus", function()
	zoom(0.1)
end)

swayimg.viewer.on_key("minus", function()
	zoom(-0.1)
end)

swayimg.viewer.on_key("c", function()
	swayimg.viewer.set_fix_scale("width")
end)

swayimg.viewer.on_scroll(function(kmods, horizontal, vertical)
	horizontal = horizontal or 0
	vertical = vertical or 0

	if kmods == "Ctrl" then
		-- zoom around the mouse pointer
		if vertical ~= 0 then
			zoom(-vertical / 10)
		end
	else
		-- pan by 5% of the window per wheel notch
		local wnd = swayimg.get_window_size()
		local pos = swayimg.viewer.get_position()
		swayimg.viewer.set_abs_position(
			math.floor(pos.x + wnd.width * 0.05 * horizontal),
			math.floor(pos.y + wnd.height * 0.05 * vertical)
		)
	end
end)

swayimg.viewer.on_mouse("MouseSide", prev_image)
swayimg.viewer.on_mouse("MouseExtra", next_image)
