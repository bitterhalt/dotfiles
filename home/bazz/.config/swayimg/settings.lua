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
swayimg.text.set_timeout(5)
swayimg.text.set_status_timeout(3)

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------
-- Text
swayimg.text.set_foreground(0xffcecdc3)
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(0xd0000000)
-- Gallery
swayimg.gallery.set_border_color(0xffA02F6F)
swayimg.gallery.set_selected_color(0xff403E3C)
swayimg.gallery.set_unselected_color(0xff1C1B1A)
-- swayimg.gallery.set_window_color(0xff100F0F)
swayimg.gallery.set_window_color(0x30000000)
--Viewer
-- swayimg.viewer.set_window_background(0xff100F0F)
swayimg.viewer.set_window_background(0x30000000)
swayimg.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
