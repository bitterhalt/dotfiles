--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.autopos = "center"
swayimg.viewer.loop = true
swayimg.viewer.preload = 1

swayimg.viewer.text = {
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

swayimg.on_window_resize(function()
	if swayimg.mode == "viewer" then
		swayimg.viewer.set_fix_scale("optimal")
	end
end)

local function with_image(fn)
	local image = swayimg.viewer.get_image()
	if image then
		fn(image)
	end
end

--------------------------------------------------------------------------------
-- Binds
--------------------------------------------------------------------------------
swayimg.viewer.on_key("q", function()
	swayimg.exit()
end)

swayimg.viewer.on_key("f", function()
	swayimg.fullscreen = not swayimg.fullscreen
end)

swayimg.viewer.on_key("<", function()
	swayimg.viewer.rotate(90)
end)

swayimg.viewer.on_key("Return", function()
	swayimg.mode = "gallery"
end)

swayimg.viewer.on_key("r", function()
	rename_image()
	swayimg.viewer.reload()
end)

swayimg.viewer.on_key("Up", function()
	swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("l", function()
	swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("Down", function()
	swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("h", function()
	swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("g", function()
	swayimg.viewer.open("first")
end)

swayimg.viewer.on_key("Shift-g", function()
	swayimg.viewer.open("last")
end)

swayimg.viewer.on_key("plus", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.scale
	swayimg.viewer.set_abs_scale(scale + scale / 10, pos.x, pos.y)
end)

swayimg.viewer.on_key("minus", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.scale
	swayimg.viewer.set_abs_scale(scale - scale / 10, pos.x, pos.y)
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
			local mouse = swayimg.get_mouse_pos()
			local scale = swayimg.viewer.scale
			swayimg.viewer.set_abs_scale(scale - scale * vertical / 10, mouse.x, mouse.y)
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
swayimg.viewer.on_mouse("MouseSide", function()
	swayimg.viewer.open("prev")
end)

swayimg.viewer.on_mouse("MouseExtra", function()
	swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("b", function()
	with_image(function(image)
		os.execute("~/.config/swayimg/setbg.sh -p " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.viewer.on_key("Shift-p", function()
	with_image(function(image)
		os.execute("setbg -pf " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.viewer.on_key("e", function()
	with_image(function(image)
		os.execute("gimp " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.viewer.on_key("y", function()
	with_image(function(image)
		os.execute("wl-copy -t image/png < " .. shellescape(image.path))
		swayimg.text.status = "Copied to clipboard: " .. image.path
	end)
end)
