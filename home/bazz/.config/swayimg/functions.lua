-- Edit .
function edit_image(image)
	if not image or not image.path then
		return
	end

	local reply = os.tmpname()
	os.execute(
		string.format(
			"printf '%%s\\n' gimp waytator | fuzzel --dmenu --minimal-lines -d --placeholder 'Edit with' > %s",
			reply
		)
	)

	local f = io.open(reply, "r")
	local choice = f and f:read("*all"):gsub("\n$", "") or ""
	if f then
		f:close()
	end
	os.remove(reply)

	if choice == "gimp" then
		os.execute("gimp " .. shellescape(image.path) .. " & disown")
	elseif choice == "waytator" then
		os.execute("waytator " .. shellescape(image.path) .. " & disown")
	end
end

-- Rename .
function rename_image()
	local image = nil
	local mode = swayimg.get_mode()
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
			swayimg.text.set_status("Renamed to: " .. new_name)
		else
			swayimg.text.set_status("Error: Rename failed")
		end
	end
end
