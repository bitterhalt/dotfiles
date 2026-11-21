-- Image currently selected (gallery) or shown (viewer).
function current_image()
	local mode = swayimg.mode
	if mode == "gallery" then
		return swayimg.gallery.get_image()
	elseif mode == "viewer" then
		return swayimg.viewer.get_image()
	end
end

-- Set the wallpaper through the Quickshell helper, then redraw the
-- wallpaper layers (WallpaperService, `qs ipc call bg reload`).
function set_wallpaper()
	local image = current_image()
	if not image or not image.path then
		return
	end

	os.execute(string.format(
		"( out=$(python3 ~/.config/quickshell/wallpaper/wallpaper-helper.py apply %s 2>&1)"
			.. " || { notify-send 'Wallpaper failed' \"$out\"; exit 1; };"
			.. " qs ipc call bg reload ) >/dev/null 2>&1 &",
		shellescape(image.path)
	))
	swayimg.text.status = "Setting wallpaper..."
end

-- Build an F1-style key tips toggle for one mode.
--   mode:  swayimg.viewer / swayimg.gallery
--   base:  the mode's normal text scheme (table with the four corners)
--   block: corner that is free to hold the tips ("topleft", "bottomleft", ...)
--   lines: tips, use "key<TAB>description" so the block gets aligned
function make_help_toggle(mode, base, block, lines)
	local shown = false

	local function apply()
		local scheme = {}
		for corner, content in pairs(base) do
			scheme[corner] = content
		end
		if shown then
			scheme[block] = lines
		end
		mode.text = scheme
		swayimg.text.visible = true
	end

	return function()
		-- If the overlay already timed out, a press shows the tips again.
		if shown and swayimg.text.visible then
			shown = false
		else
			shown = true
		end
		apply()
	end
end
