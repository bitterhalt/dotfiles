--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(160)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

local register_external_cmds = require("functions/external_cmds")

-- Configure Gallery Layout & Text Hints
swayimg.gallery.set_text("topleft", {
	"[b] -> Set Wallpaper",
	"[p] -> Wallpaper with Pywal  [Shift+p] -> Wallpaper with Pywal alternative",
})

swayimg.gallery.set_text("topright", {
	"[e] -> Edit (GIMP)",
	"[y] -> Copy to Clipboard",
})
swayimg.gallery.set_text("bottomleft", { "{list.index} of {list.total}" })
swayimg.gallery.set_text("bottomright", { "{name}" })

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

-- Thumbnail size
swayimg.gallery.on_key("Minus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() - 20)
end)
swayimg.gallery.on_key("Plus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)

-- Trash
swayimg.gallery.on_key("Delete", function()
	local image = swayimg.gallery.get_image()
	if image then
		os.execute("trash-put " .. shellescape(image.path))
		swayimg.text.set_status("File trashed: " .. image.path)
	end
end)

register_external_cmds(swayimg.gallery)

swayimg.gallery.on_image_change(function()
	local image = swayimg.gallery.get_image()
	swayimg.set_title("Gallery: " .. image.path)
end)
