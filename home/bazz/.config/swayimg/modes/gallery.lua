--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(160)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

swayimg.gallery.set_text("topright", { "{list.index} of {list.total}" })
swayimg.gallery.set_text("bottomright", { "{name}" })
swayimg.gallery.set_text("topleft", {})
swayimg.gallery.set_text("bottomleft", {})

swayimg.gallery.on_image_change(function()
	local image = swayimg.gallery.get_image()
	swayimg.set_title("Gallery: " .. image.path)
end)
