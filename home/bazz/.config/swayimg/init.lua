require("modes/init")
require("binds/init")

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
swayimg.text.set_font("Adwaita Mono")
swayimg.text.set_size(13)
swayimg.text.set_padding(10)
swayimg.text.set_timeout(15)
swayimg.text.set_status_timeout(3)

--------------------------------------------------------------------------------
-- Colors - Load from Pywal
--------------------------------------------------------------------------------
local colors_path = os.getenv("HOME") .. "/.cache/wal/colors.lua"
local colors = nil

if io.open(colors_path, "r") then
	colors = dofile(colors_path)
end

-- Fallback colors if pywal colors not available
if not colors then
	colors = {
		color7 = "#cccccc",
		color5 = "#A02F6F",
		color8 = "#403E3C",
		color0 = "#1C1B1A",
	}
end

local function hex_to_argb(hex)
	hex = hex:gsub("#", "")
	return 0xff000000 + tonumber(hex, 16)
end

-- Text
swayimg.text.set_foreground(hex_to_argb(colors.color7))
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(0xd0000000)

-- Gallery
swayimg.gallery.set_border_color(hex_to_argb(colors.color6))
swayimg.gallery.set_selected_color(hex_to_argb(colors.color8))
swayimg.gallery.set_unselected_color(hex_to_argb(colors.color0))
swayimg.gallery.set_window_color(0x30000000)

-- Viewer
swayimg.viewer.set_window_background(0x30000000)
swayimg.viewer.set_image_chessboard(20, hex_to_argb(colors.color8), hex_to_argb(colors.color7))
