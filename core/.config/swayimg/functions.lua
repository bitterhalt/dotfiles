-- Rename .
function rename_image()
	local image = nil
	local mode = swayimg.mode
	if mode == "gallery" then
		image = swayimg.gallery.get_image()
	elseif mode == "viewer" then
		image = swayimg.viewer.get_image()
	end

	if not image or not image.path then
		return
	end

	local dir = image.path:match("(.*/)") or ""
	local current_name = image.path:match("^.*/([^/]+)$") or image.path

	local reply = os.tmpname()
	os.execute(
		string.format(
			"echo %s | fuzzel --minimal-lines -d --placeholder 'Rename ' > %s",
			shellescape(current_name),
			reply
		)
	)

	local f = io.open(reply, "r")
	local new_name = f and f:read("*all"):gsub("\n$", "") or ""
	if f then
		f:close()
	end
	os.remove(reply)

	if new_name ~= "" and new_name ~= current_name then
		local new_path = dir .. new_name
		local success = os.rename(image.path, new_path)

		if success then
			swayimg.text.status = "Renamed to: " .. new_name
		else
			swayimg.text.status = "Error: Rename failed"
		end
	end
end

function run_hellwal()
	local image = nil
	local mode = swayimg.mode
	if mode == "gallery" then
		image = swayimg.gallery.get_image()
	elseif mode == "viewer" then
		image = swayimg.viewer.get_image()
	end

	if not image or not image.path then
		return
	end

	os.execute(
		string.format(
			"( out=$(setbg -p %s 2>&1) || notify-send 'Wallpaper failed' \"$out\" ) >/dev/null 2>&1 &",
			shellescape(image.path)
		)
	)
	swayimg.text.status = "Applying wallpaper + hellwal..."
end
