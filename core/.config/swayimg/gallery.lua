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
	"b\tSet as wallpaper",
	"y\tCopy image to clipboard",
	"e\tEdit in GIMP",
	"Delete\tMove to trash",
	"h j k l\tMove selection",
	"g / Shift-g\tFirst / last",
	"- / +\tThumbnail size",
	"Return\tOpen in viewer",
	"f\tFullscreen",
	"q\tQuit",
}

local function with_image(fn)
	local image = swayimg.gallery.get_image()
	if image then
		fn(image)
	end
end

--------------------------------------------------------------------------------
-- Binds
--------------------------------------------------------------------------------
swayimg.gallery.on_key("F1", make_help_toggle(swayimg.gallery, text, "topleft", help))

swayimg.gallery.on_key("q", function()
	swayimg.exit()
end)

swayimg.gallery.on_key("f", function()
	swayimg.toggle_fullscreen()
end)

swayimg.gallery.on_key("Return", function()
	swayimg.mode = "viewer"
end)

swayimg.gallery.on_key("g", function()
	swayimg.gallery.switch_image("first")
end)

swayimg.gallery.on_key("Shift-g", function()
	swayimg.gallery.switch_image("last")
end)

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

swayimg.gallery.on_key("Minus", function()
	swayimg.gallery.thumb_size = swayimg.gallery.thumb_size - 20
end)

swayimg.gallery.on_key("Plus", function()
	swayimg.gallery.thumb_size = swayimg.gallery.thumb_size + 20
end)

swayimg.gallery.on_key("Delete", function()
	with_image(function(image)
		os.execute("trash-put " .. shellescape(image.path))
		swayimg.text.status = "File trashed: " .. image.path
	end)
end)

swayimg.gallery.on_key("b", set_wallpaper)

swayimg.gallery.on_key("e", function()
	with_image(function(image)
		os.execute("gimp " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.gallery.on_key("y", function()
	with_image(function(image)
		os.execute("wl-copy -t image/png < " .. shellescape(image.path))
		swayimg.text.status = "Copied to clipboard: " .. image.path
	end)
end)

swayimg.gallery.on_image_change(function()
	with_image(function(image)
		swayimg.title = "Gallery: " .. image.path
	end)
end)
