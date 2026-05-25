local function read_cmd(cmd)
	local f = io.popen(cmd)
	if not f then
		return nil
	end
	local out = f:read("*l")
	f:close()
	return out
end

-- Get resolution and detect compositor
local function get_resolution()
	local is_niri = false

	-- Niri
	if os.execute("command -v niri >/dev/null 2>&1") == 0 then
		local cmd = "niri msg --json outputs | jq -r 'to_entries | .[0].value.logical | \"\\(.width) \\(.height)\"'"
		local out = read_cmd(cmd)
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				is_niri = true
				return w, h, is_niri
			end
		end
	end

	-- Hyprland
	if os.execute("command -v hyprctl >/dev/null 2>&1") == 0 then
		local out = read_cmd("hyprctl -j monitors | jq -r '.[] | select(.focused) | \"\\(.width) \\(.height)\"'")
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				return w, h, false
			end
		end
	end

	return nil, nil, false
end

local function setbg(path)
	path = path:gsub("'", "'\\''")

	local w, h, is_niri = get_resolution()
	if not w or not h then
		swayimg.text.set_status("setbg: failed to detect resolution")
		return
	end

	local home = os.getenv("HOME")
	local dir = home .. "/.local/share/wall/"
	local out = dir .. "wallpaper.png"
	local lockscreen = dir .. "lockscreen.png"

	os.execute("mkdir -p '" .. dir .. "'")
	os.execute("vipsthumbnail '" .. path .. "' --size " .. w .. "x" .. h .. " --output '" .. out .. "'")

	-- Apply main wallpaper
	os.execute("awww img '" .. out .. "' --transition-type=none")

	-- Generate blurred overview and set namespace if Niri
	if is_niri then
		os.execute("gm convert '" .. out .. "' -blur 0x30 -modulate 80 '" .. lockscreen .. "'")
		os.execute("awww img -n overview '" .. lockscreen .. "' --transition-type=none")

		swayimg.text.set_status("Updated: Default + Overview namespaces")
	else
		swayimg.text.set_status("Updated: Default wallpaper")
	end
end

return setbg
