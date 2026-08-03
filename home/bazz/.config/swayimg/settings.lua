--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.mode = "viewer"
swayimg.antialiasing = true
swayimg.decoration = true
swayimg.overlay = false
swayimg.dnd_button = "MouseRight" -- mouse drag and drop

--------------------------------------------------------------------------------
-- Image list
--------------------------------------------------------------------------------
swayimg.imagelist.order = "alpha"
swayimg.imagelist.reverse = false
swayimg.imagelist.recursive = false
swayimg.imagelist.adjacent = true

--------------------------------------------------------------------------------
-- Text / font overlay
--------------------------------------------------------------------------------
swayimg.text.font = "Adwaita Mono"
swayimg.text.size = 13
swayimg.text.padding = 10
swayimg.text.timeout = 15
swayimg.text.status_timeout = 3

--------------------------------------------------------------------------------
-- Colors - Load from Pywal
--------------------------------------------------------------------------------
local colors_path = os.getenv("HOME") .. "/.cache/wal/colors.lua"
local colors = nil

local f = io.open(colors_path, "r")
if f then
	f:close()
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
swayimg.text.color = hex_to_argb(colors.color7)
swayimg.text.background = 0x00000000
swayimg.text.shadow = 0xd0000000

-- Gallery
swayimg.gallery.border_color = hex_to_argb(colors.color6)
swayimg.gallery.selected_color = hex_to_argb(colors.color8)
swayimg.gallery.unselected_color = hex_to_argb(colors.color0)
swayimg.gallery.window_color = hex_to_argb(colors.color0)

-- Viewer
swayimg.viewer.set_window_background(hex_to_argb(colors.color0))
swayimg.viewer.set_image_chessboard(20, hex_to_argb(colors.color8), hex_to_argb(colors.color7))
