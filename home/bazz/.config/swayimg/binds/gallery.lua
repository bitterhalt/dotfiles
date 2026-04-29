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

-- Navigation (vim-style)
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

-- Thumbnail size adjust
swayimg.gallery.on_key("Minus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() - 20)
end)

swayimg.gallery.on_key("Plus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)

-- External commands
swayimg.gallery.on_key("Delete", function()
	local image = swayimg.gallery.get_image()
	os.execute("trash-put '" .. image.path .. "'")
	swayimg.text.set_status("File trashed: " .. image.path)
end)

swayimg.gallery.on_key("b", function()
	local image = swayimg.gallery.get_image()
	setbg(image.path)
end)

swayimg.gallery.on_key("e", function()
	local image = swayimg.gallery.get_image()
	os.execute("gimp '" .. image.path .. "' & disown")
end)

swayimg.gallery.on_key("y", function()
	local image = swayimg.gallery.get_image()
	os.execute("wl-copy -t image/png <'" .. image.path .. "'")
	swayimg.text.set_status("File " .. image.path .. " Copied to clipboard")
end)
