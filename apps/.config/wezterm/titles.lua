local wezterm = require("wezterm")
local M = {}

local shells = {
	bash = true,
	zsh = true,
	fish = true,
	sh = true,
	nu = true,
	pwsh = true,
}

-- Strip "user@host: " prefixes
function M.clean(title)
	return ((title or ""):gsub("^[^@%s]+@[^:%s]+:%s*", ""))
end

-- Extract folder name (or "~") from pane's current working directory
local function get_folder_name(pane)
	local cwd_uri = pane:get_current_working_dir()
	if not cwd_uri then
		return nil
	end

	local path = type(cwd_uri) == "userdata" and cwd_uri.file_path or tostring(cwd_uri):gsub("^file://[^/]*", "")
	path = path:gsub("/+$", "")

	if path == wezterm.home_dir then
		return "~"
	end
	return path:match("([^/]+)$") or path
end

-- Smart title: app name when running a program, folder name when idle, always sanitized
function M.smart(pane)
	local raw_clean = M.clean(pane:get_title())

	local proc_path = pane:get_foreground_process_name() or ""
	local proc_name = proc_path:match("([^/\\]+)$") or ""

	if proc_name ~= "" and not shells[proc_name] then
		return M.clean(proc_name)
	end

	local folder = get_folder_name(pane)
	if folder and folder ~= "" then
		return M.clean(folder)
	end

	return raw_clean
end

-- true if the (mux) tab's active pane is zoomed
function M.is_zoomed(tab)
	for _, p in ipairs(tab:panes_with_info()) do
		if p.is_active then
			return p.is_zoomed
		end
	end
	return false
end

-- Window title (what niri shows)
function M.setup()
	wezterm.on("format-window-title", function(tab, pane, tabs, panes, cfg)
		local zoomed = tab.active_pane.is_zoomed and "[Z] " or ""
		local mux_pane = wezterm.mux.get_pane(tab.active_pane.pane_id)
		local title = mux_pane and M.smart(mux_pane) or M.clean(tab.active_pane.title)
		return zoomed .. wezterm.truncate_right(title, 40)
	end)
end

return M
