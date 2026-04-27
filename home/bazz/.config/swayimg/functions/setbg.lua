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
		local out =
			read_cmd("niri msg --json focused-output | jq -r '\"\\(.current_mode.width) \\(.current_mode.height)\"'")
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

	-- sway
	if os.execute("command -v swaymsg >/dev/null 2>&1") == 0 then
		local out = read_cmd(
			"swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | \"\\(.current_mode.width) \\(.current_mode.height)\"'"
		)
		if out then
			local w, h = out:match("(%d+) (%d+)")
			if w and h then
				return w, h
			end
		end
	end

	-- wlr-randr
	if os.execute("command -v wlr-randr >/dev/null 2>&1") == 0 then
		local out =
			read_cmd("wlr-randr | awk '/^[A-Za-z0-9-]+/{out=$1} /\\*/{split($1,r,\"x\"); print r[1],r[2]; exit}'")
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

	os.execute("mkdir -p '" .. dir .. "'")
	os.execute("vipsthumbnail '" .. path .. "' --size " .. w .. "x" .. h .. " --output '" .. out .. "'")
	os.execute(
		"awww img '"
			.. out
			.. "'"
			.. " --transition-type=any"
			.. " --transition-step=60"
			.. " --transition-fps=60"
			.. " --transition-duration=.7"
	)

	swayimg.text.set_status("Wallpaper set")
end

return setbg
