--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(160)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

-- Configure Gallery Layout & Text Hints
swayimg.gallery.set_text("topleft", {
	"[b] -> Set Wallpaper",
	"[p] -> Wallpaper with Pywal  [Shift+p] -> Wallpaper with Pywal alternative",
})
swayimg.gallery.set_text("topright", {
	"[e] -> Edit (GIMP)",
	"[y] -> Copy to Clipboard",
	"[r] -> Rename File",
})
swayimg.gallery.set_text("bottomleft", { "{list.index} of {list.total}" })
swayimg.gallery.set_text("bottomright", { "{name}" })

local function with_image(fn)
	local image = swayimg.gallery.get_image()
	if image then
		fn(image)
	end
end

--------------------------------------------------------------------------------
-- Binds
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

swayimg.gallery.on_key("r", function()
	rename_image()
	swayimg.gallery.reload()
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
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() - 20)
end)

swayimg.gallery.on_key("Plus", function()
	swayimg.gallery.set_thumb_size(swayimg.gallery.get_thumb_size() + 20)
end)

swayimg.gallery.on_key("Delete", function()
	with_image(function(image)
		os.execute("trash-put " .. shellescape(image.path))
		swayimg.text.set_status("File trashed: " .. image.path)
	end)
end)

swayimg.gallery.on_key("b", function()
	with_image(function(image)
		os.execute("setbg -w " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.gallery.on_key("p", function()
	with_image(function(image)
		os.execute("setbg -p " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.gallery.on_key("Shift-p", function()
	with_image(function(image)
		os.execute("setbg -pf " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.gallery.on_key("e", function()
	with_image(function(image)
		os.execute("gimp " .. shellescape(image.path) .. " & disown")
	end)
end)

swayimg.gallery.on_key("y", function()
	with_image(function(image)
		os.execute("wl-copy -t image/png < " .. shellescape(image.path))
		swayimg.text.set_status("Copied to clipboard: " .. image.path)
	end)
end)

swayimg.gallery.on_image_change(function()
	with_image(function(image)
		swayimg.set_title("Gallery: " .. image.path)
	end)
end)
