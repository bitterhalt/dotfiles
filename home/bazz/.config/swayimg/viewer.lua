--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.set_default_position("center")
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.limit_preload(1)

swayimg.viewer.set_text("topleft", {
	"File: {name}",
	"Format: {format}",
	"File size: {sizehr}",
	"Size: {frame.width}x{frame.height}",
	"{meta.Exif.Photo.DateTimeOriginal}",
	"{meta.Exif.Image.Model}",
})
swayimg.viewer.set_text("topright", {
	"Image: {list.index} of {list.total}",
	"Frame: {frame.index} of {frame.total}",
	"Scale: {scale}",
})
swayimg.viewer.set_text("bottomleft", {})
swayimg.viewer.set_text("bottomright", {})

swayimg.on_window_resize(function()
	if swayimg.get_mode() == "viewer" then
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
	swayimg.toggle_fullscreen()
end)

swayimg.viewer.on_key("r", function()
	swayimg.viewer.rotate(90)
end)

swayimg.viewer.on_key("Return", function()
	swayimg.set_mode("gallery")
end)

swayimg.viewer.on_key("r", function()
	rename_image()
	swayimg.viewer.reload()
end)

swayimg.viewer.on_key("Up", function()
	swayimg.viewer.switch_image("next")
end)

swayimg.viewer.on_key("l", function()
	swayimg.viewer.switch_image("next")
end)

swayimg.viewer.on_key("Down", function()
	swayimg.viewer.switch_image("prev")
end)

swayimg.viewer.on_key("h", function()
	swayimg.viewer.switch_image("prev")
end)

swayimg.viewer.on_key("g", function()
	swayimg.viewer.switch_image("first")
end)

swayimg.viewer.on_key("Shift-g", function()
	swayimg.viewer.switch_image("last")
end)

swayimg.viewer.on_key("plus", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.get_scale()
	swayimg.viewer.set_abs_scale(scale + scale / 10, pos.x, pos.y)
end)

swayimg.viewer.on_key("minus", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.get_scale()
	swayimg.viewer.set_abs_scale(scale - scale / 10, pos.x, pos.y)
end)

swayimg.viewer.on_key("c", function()
	swayimg.viewer.set_fix_scale("width")
end)

swayimg.viewer.on_mouse("ScrollLeft", function()
	local wnd = swayimg.get_window_size()
	local pos = swayimg.viewer.get_position()
	swayimg.viewer.set_abs_position(math.floor(pos.x - wnd.width * 0.05), pos.y)
end)

swayimg.viewer.on_mouse("ScrollRight", function()
	local wnd = swayimg.get_window_size()
	local pos = swayimg.viewer.get_position()
	swayimg.viewer.set_abs_position(math.floor(pos.x + wnd.width * 0.05), pos.y)
end)

swayimg.viewer.on_mouse("ScrollUp", function()
	local wnd = swayimg.get_window_size()
	local pos = swayimg.viewer.get_position()
	swayimg.viewer.set_abs_position(pos.x, math.floor(pos.y - wnd.height * 0.05))
end)

swayimg.viewer.on_mouse("ScrollDown", function()
	local wnd = swayimg.get_window_size()
	local pos = swayimg.viewer.get_position()
	swayimg.viewer.set_abs_position(pos.x, math.floor(pos.y + wnd.height * 0.05))
end)

swayimg.viewer.on_mouse("Ctrl-ScrollUp", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.get_scale()
	swayimg.viewer.set_abs_scale(scale + scale / 10, pos.x, pos.y)
end)

swayimg.viewer.on_mouse("Ctrl-ScrollDown", function()
	local pos = swayimg.get_mouse_pos()
	local scale = swayimg.viewer.get_scale()
	swayimg.viewer.set_abs_scale(scale - scale / 10, pos.x, pos.y)
end)

swayimg.viewer.on_mouse("MouseSide", function()
	swayimg.viewer.switch_image("prev")
end)

swayimg.viewer.on_mouse("MouseExtra", function()
	swayimg.viewer.switch_image("next")
end)

swayimg.viewer.on_key("b", function()
	with_image(function(image)
		os.execute("setbg -w " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.viewer.on_key("p", function()
	with_image(function(image)
		os.execute("setbg -p " .. shellescape(image.path) .. " & disown")
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
		swayimg.text.set_status("Copied to clipboard: " .. image.path)
	end)
end)
