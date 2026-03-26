--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.set_mode("viewer")
swayimg.enable_antialiasing(true)
swayimg.enable_decoration(true)
swayimg.enable_overlay(false)
swayimg.set_dnd_button("MouseRight") -- mouse drag and drop

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
swayimg.text.set_foreground(0xffcecdc3)
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(0xd0000000)
swayimg.text.set_timeout(5)
swayimg.text.set_status_timeout(3)
