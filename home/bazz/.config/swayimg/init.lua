--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.set_mode("viewer")
swayimg.enable_antialiasing(true)
swayimg.enable_decoration(true)
swayimg.enable_overlay(false)

--------------------------------------------------------------------------------
-- Image list
--------------------------------------------------------------------------------
swayimg.imagelist.set_order("alpha")
swayimg.imagelist.enable_reverse(false)
swayimg.imagelist.enable_recursive(false)
swayimg.imagelist.enable_adjacent(true)

--------------------------------------------------------------------------------
-- Text / font overlay
--------------------------------------------------------------------------------
swayimg.text.set_font("monospace")
swayimg.text.set_size(14)
swayimg.text.set_padding(10)
swayimg.text.set_foreground(0xffAF3029)
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(0xd0000000)
swayimg.text.set_timeout(5)
swayimg.text.set_status_timeout(3)

--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.set_default_scale("optimal")
swayimg.viewer.set_default_position("center")
swayimg.viewer.set_drag_button("MouseLeft")
swayimg.viewer.set_window_background(0xD0000000)
swayimg.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.limit_preload(1)

-- top_left = +name,+format,+filesize,+imagesize,+exif
swayimg.viewer.set_text("topleft", {
	"File: {name}",
	"Format: {format}",
	"File size: {sizehr}",
	"Size: {frame.width}x{frame.height}",
	"EXIF date: {meta.Exif.Photo.DateTimeOriginal}",
	"EXIF camera: {meta.Exif.Image.Model}",
})

-- top_right = index
swayimg.viewer.set_text("topright", {
	"Image: {list.index} of {list.total}",
	"Frame: {frame.index} of {frame.total}",
	"Scale: {scale}",
})

-- bottom_left = scale,frame
swayimg.viewer.set_text("bottomleft", {
	-- add something
})

-- bottom_right = status  (status messages appear here automatically)
swayimg.viewer.set_text("bottomright", {})

--------------------------------------------------------------------------------
-- Slideshow mode
--------------------------------------------------------------------------------
swayimg.slideshow.set_timeout(3) -- time = 3
swayimg.slideshow.set_default_scale("fit")
swayimg.slideshow.set_window_background("auto")

-- bottom_right = dir,status
swayimg.slideshow.set_text("bottomright", { "{path}", "{status}" })
swayimg.slideshow.set_text("topleft", {})
swayimg.slideshow.set_text("topright", {})
swayimg.slideshow.set_text("bottomleft", {})

--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(180)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.set_border_color(0xff24837B)
swayimg.gallery.set_selected_color(0xff403E3C)
swayimg.gallery.set_unselected_color(0xff1C1B1A)
swayimg.gallery.set_window_color(0xAA000000)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

-- top_right = index
swayimg.gallery.set_text("topright", { "{list.index} of {list.total}" })

-- bottom_right = name,status
swayimg.gallery.set_text("bottomright", { "{name}" })
swayimg.gallery.set_text("topleft", {})
swayimg.gallery.set_text("bottomleft", {})

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
swayimg.viewer.on_key("equal", function()
	swayimg.viewer.set_scale("zoom", 10)
end)

swayimg.viewer.on_key("plus", function()
	swayimg.viewer.set_scale("zoom", 10)
end)

swayimg.viewer.on_key("minus", function()
	swayimg.viewer.set_scale("zoom", -10)
end)

swayimg.viewer.on_key("Shift-equal", function()
	swayimg.viewer.set_fix_scale("width")
end)

swayimg.viewer.on_key("Shift-e", function()
	swayimg.viewer.set_fix_scale("height")
end)

-- Thumbnail size adjust (Equal/Minus/Plus = thumb ±20)
swayimg.viewer.on_key("Equal", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)

swayimg.viewer.on_key("Minus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() - 20)
end)

swayimg.viewer.on_key("Plus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)

-- External commands
swayimg.viewer.on_key("Delete", function()
	local image = swayimg.viewer.get_image()
	os.execute("trash-put '" .. image.path .. "'")
	swayimg.text.set_status("File trashed: " .. image.path)
end)

swayimg.viewer.on_key("b", function()
	local image = swayimg.viewer.get_image()
	os.execute("setbg '" .. image.path .. "'")
	swayimg.text.set_status("Wallpaper set")
end)

swayimg.viewer.on_key("e", function()
	local image = swayimg.viewer.get_image()
	os.execute("gimp '" .. image.path .. "' & disown")
end)

swayimg.viewer.on_key("y", function()
	local image = swayimg.viewer.get_image()
	local name = image.path:match("(.+)%..+$") or image.path
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

-- Alt+Scroll: frame navigation (animations)
swayimg.viewer.on_mouse("Alt-ScrollUp", function()
	swayimg.viewer.switch_frame("prev")
end)

swayimg.viewer.on_mouse("Alt-ScrollDown", function()
	swayimg.viewer.switch_frame("next")
end)

--------------------------------------------------------------------------------
-- Key bindings: Gallery mode
--------------------------------------------------------------------------------

swayimg.gallery.on_key("q", function()
	swayimg.exit()
end)

swayimg.gallery.on_key("f", function()
	swayimg.toggle_fullscreen()
end)

swayimg.gallery.on_key("Return", function()
	swayimg.set_mode("viewer")
end)

swayimg.gallery.on_key("g", function()
	swayimg.gallery.switch_image("first")
end)

swayimg.gallery.on_key("Shift-g", function()
	swayimg.gallery.switch_image("last")
end)

-- Navigation (vim-style + arrows)
swayimg.gallery.on_key("h", function()
	swayimg.gallery.switch_image("left")
end)

swayimg.gallery.on_key("j", function()
	swayimg.gallery.switch_image("down")
end)

swayimg.gallery.on_key("k", function()
	swayimg.gallery.switch_image("up")
end)

swayimg.gallery.on_key("l", function()
	swayimg.gallery.switch_image("right")
end)

swayimg.gallery.on_key("Delete", function()
	local image = swayimg.gallery.get_image()
	os.execute("trash-put '" .. image.path .. "'")
	swayimg.text.set_status("File trashed: " .. image.path)
end)

swayimg.gallery.on_key("b", function()
	local image = swayimg.gallery.get_image()
	os.execute("setbg '" .. image.path .. "'")
	swayimg.text.set_status("Wallpaper set")
end)

swayimg.gallery.on_key("e", function()
	local image = swayimg.gallery.get_image()
	os.execute("gimp '" .. image.path .. "' & disown")
end)

swayimg.gallery.on_key("y", function()
	local image = swayimg.gallery.get_image()
	local name = image.path:match("(.+)%..+$") or image.path
	os.execute("wl-copy -t image/png <'" .. image.path .. "'")
	swayimg.text.set_status("File " .. image.path .. " Copied to clipboard")
end)
