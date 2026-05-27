local shellescape = require("functions/shellescape")

local function read_cmd(cmd)
	local f = io.popen(cmd)
	if not f then
		return nil
	end
	local out = f:read("*l")
	f:close()
	return out
end

local function get_resolution()
	if os.execute("command -v niri >/dev/null 2>&1") == 0 then
		local cmd = "niri msg --json outputs | jq -r 'to_entries | .[0].value.logical | \"\\(.width) \\(.height)\"'"
		local out = read_cmd(cmd)
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				return w, h, true
			end
		end
	end

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
	local escaped = shellescape(path)
	local w, h, is_niri = get_resolution()
	if not w or not h then
		swayimg.text.set_status("setbg: failed to detect resolution")
		return
	end

	local dir = os.getenv("HOME") .. "/.local/share/wall/"
	local out = dir .. "wallpaper.png"
	local lockscreen = dir .. "lockscreen.png"

	os.execute("mkdir -p " .. shellescape(dir))
	os.execute("vipsthumbnail " .. escaped .. " --size " .. w .. "x" .. h .. " --output " .. shellescape(out))
	os.execute("awww img " .. shellescape(out) .. " --transition-type=none")

	if is_niri then
		os.execute("gm convert " .. shellescape(out) .. " -blur 0x30 -modulate 80 " .. shellescape(lockscreen))
		os.execute("awww img -n overview " .. shellescape(lockscreen) .. " --transition-type=none")
		swayimg.text.set_status("Updated: Default + Overview namespaces")
	else
		swayimg.text.set_status("Updated: Default wallpaper")
	end
end

return setbg
