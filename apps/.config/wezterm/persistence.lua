local wezterm = require("wezterm")
local M = {}

local FALLBACK_WORKSPACE = "default"

function M.setup(config)
	-- Remember the last persistent workspace across window close/open.
	-- Stored in the runtime dir, so it resets on logout/reboot together with the mux server.
	local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
	local last_ws_file = runtime_dir .. "/wezterm-last-workspace"

	local function workspace_has_windows(name)
		for _, mux_win in ipairs(wezterm.mux.all_windows()) do
			if mux_win:get_workspace() == name then
				return true
			end
		end
		return false
	end

	local function save_workspace(name)
		local out = io.open(last_ws_file, "w")
		if out then
			out:write(name, "\n")
			out:close()
		end
	end

	local function read_saved_workspace()
		local f = io.open(last_ws_file, "r")
		if not f then
			return nil
		end
		local name = f:read("*l")
		f:close()
		if name and name ~= "" then
			return name
		end
		return nil
	end

	local saved = read_saved_workspace()
	if saved and workspace_has_windows(saved) then
		config.default_workspace = saved
	else
		-- Stale or empty name: fall back to a clean default so the binds work.
		config.default_workspace = FALLBACK_WORKSPACE
		save_workspace(FALLBACK_WORKSPACE)
	end

	local last_saved = config.default_workspace
	wezterm.on("update-status", function(window, pane)
		if pane:get_domain_name() ~= "unix" then
			return
		end

		local ws = window:active_workspace()
		if ws == last_saved then
			return
		end

		if workspace_has_windows(ws) then
			last_saved = ws
			save_workspace(ws)
		end
	end)

	-- Tmux-style persistence
	config.unix_domains = { { name = "unix" } }
	config.default_gui_startup_args = { "connect", "unix" }
end

return M
