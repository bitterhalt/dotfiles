--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.thumb_size = 160
swayimg.gallery.padding_size = 10
swayimg.gallery.border_size = 2
swayimg.gallery.cache = 100
swayimg.gallery.preload = false
swayimg.gallery.pstore = true

local text = {
	topleft = {},
	topright = {},
	bottomleft = { "{list.index} of {list.total}" },
	bottomright = { "{name}" },
}
swayimg.gallery.text = text

local help = {
	"Gallery keys (F1 to close)",
	"",
	help_common.wallpaper,
	help_common.copy,
	help_common.edit,
	"Delete	Move to trash",
	"h j k l	Move selection",
	help_common.first_last,
	"- / +	Thumbnail size",
	"Return	Open in viewer",
	help_common.fullscreen,
	help_common.quit,
}

--------------------------------------------------------------------------------
-- Binds
--------------------------------------------------------------------------------
swayimg.gallery.on_key("F1", make_help_toggle(swayimg.gallery, text, "topleft", help))
bind_common(swayimg.gallery)

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

swayimg.gallery.on_key("minus", function()
	swayimg.gallery.thumb_size = swayimg.gallery.thumb_size - 20
end)

swayimg.gallery.on_key("plus", function()
	swayimg.gallery.thumb_size = swayimg.gallery.thumb_size + 20
end)

swayimg.gallery.on_key("Delete", function()
	with_image(function(image)
		os.execute("trash-put " .. shellescape(image.path))
		swayimg.text.status = "File trashed: " .. image.path
	end)
end)

swayimg.gallery.on_image_change(function()
	with_image(function(image)
		swayimg.title = "Gallery: " .. image.path
	end)
end)
