--------------------------------------------------------------------------------
-- Key bindings: Viewer mode
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

-- Navigation
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

-- Zoom
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

-- External commands
swayimg.viewer.on_key("b", function()
	local image = swayimg.viewer.get_image()
	setbg(image.path)
end)

swayimg.viewer.on_key("e", function()
	local image = swayimg.viewer.get_image()
	os.execute("gimp '" .. image.path .. "' & disown")
end)

swayimg.viewer.on_key("y", function()
	local image = swayimg.viewer.get_image()
	os.execute("wl-copy -t image/png <'" .. image.path .. "'")
	swayimg.text.set_status("File " .. image.path .. " Copied to clipboard")
end)

-- Mouse scroll: pan
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

-- Mouse scroll + Ctrl: zoom at cursor
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

-- Mouse side buttons: file navigation
swayimg.viewer.on_mouse("MouseSide", function()
	swayimg.viewer.switch_image("prev")
end)
swayimg.viewer.on_mouse("MouseExtra", function()
	swayimg.viewer.switch_image("next")
end)
