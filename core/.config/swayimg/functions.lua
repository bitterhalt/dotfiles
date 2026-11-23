-- Image currently selected (gallery) or shown (viewer).
function current_image()
	local mode = swayimg.mode
	if mode == "gallery" then
		return swayimg.gallery.get_image()
	elseif mode == "viewer" then
		return swayimg.viewer.get_image()
	end
end

-- Run fn with the current image when there is one.
function with_image(fn)
	local image = current_image()
	if image then
		fn(image)
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

-- Help lines shared by viewer and gallery.
help_common = {
	wallpaper = "b	Set as wallpaper",
	copy = "y	Copy image to clipboard",
	edit = "e	Edit in Pinta",
	first_last = "g / Shift-g	First / last",
	fullscreen = "f	Fullscreen",
	quit = "q	Quit",
}

-- Switch between viewer and gallery.
function toggle_mode()
	swayimg.mode = swayimg.mode == "viewer" and "gallery" or "viewer"
end

-- Jump to the first or last image in the current mode.
function jump_image(where)
	if swayimg.mode == "gallery" then
		swayimg.gallery.switch_image(where)
	else
		swayimg.viewer.open(where)
	end
end

function edit_image()
	with_image(function(image)
		os.execute("pinta " .. shellescape(image.path) .. " & disown")
	end)
end

function copy_image()
	with_image(function(image)
		os.execute("wl-copy -t image/png < " .. shellescape(image.path))
		swayimg.text.status = "Copied to clipboard: " .. image.path
	end)
end

-- Bind the keys that behave the same in viewer and gallery.
function bind_common(mode)
	mode.on_key("q", function()
		swayimg.exit()
	end)

	mode.on_key("f", function()
		swayimg.fullscreen = not swayimg.fullscreen
	end)

	mode.on_key("Return", toggle_mode)
	mode.on_key("g", function()
		jump_image("first")
	end)
	mode.on_key("Shift-g", function()
		jump_image("last")
	end)
	mode.on_key("b", set_wallpaper)
	mode.on_key("e", edit_image)
	mode.on_key("y", copy_image)
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
