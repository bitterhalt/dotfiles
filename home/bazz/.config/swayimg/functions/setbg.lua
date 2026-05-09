local function read_cmd(cmd)
	local f = io.popen(cmd)
	if not f then
		return nil
	end
	local out = f:read("*l")
	f:close()
	return out
end

-- get resolution
local function get_resolution()
	-- niri
	if os.execute("command -v niri >/dev/null 2>&1") == 0 then
		local cmd = "niri msg --json outputs | jq -r 'to_entries | .[0].value.logical | \"\\(.width) \\(.height)\"'"
		local out = read_cmd(cmd)
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				return w, h
			end
		end
	end

	-- hyprland
	if os.execute("command -v hyprctl >/dev/null 2>&1") == 0 then
		local out = read_cmd("hyprctl -j monitors | jq -r '.[] | select(.focused) | \"\\(.width) \\(.height)\"'")
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				return w, h
			end
		end
	end

	return nil, nil
end

local function setbg(path)
	path = path:gsub("'", "'\\''")

	local w, h = get_resolution()
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
	os.execute("gm convert '" .. out .. "' -blur 0x15 '" .. lockscreen .. "'")

	os.execute(
		"awww img '"
			.. out
			.. "' "
			.. "--transition-type=any --transition-step=60 --transition-fps=60 --transition-duration=.7"
	)
	os.execute("awww img -n overview '" .. lockscreen .. "' --transition-type=none")
	swayimg.text.set_status("Wallpapers updated (Default + Overview)")
end

return setbg
