--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(180)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.set_border_color(0xffA02F6F)
swayimg.gallery.set_selected_color(0xff403E3C)
swayimg.gallery.set_unselected_color(0xff1C1B1A)
swayimg.gallery.set_window_color(0xff100F0F)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

swayimg.gallery.set_text("topright", { "{list.index} of {list.total}" })
swayimg.gallery.set_text("bottomright", { "{name}" })
swayimg.gallery.set_text("topleft", {})
swayimg.gallery.set_text("bottomleft", {})
