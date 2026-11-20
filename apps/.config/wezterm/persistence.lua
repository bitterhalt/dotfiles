local wezterm = require("wezterm")
local M = {}

function M.setup(config)
	-- Remember the last persistent workspace across window close/open.
	-- Stored in the runtime dir, so it resets on logout/reboot together with the mux server.
	local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
	local last_ws_file = runtime_dir .. "/wezterm-last-workspace"

	local f = io.open(last_ws_file, "r")
	if f then
		local name = f:read("*l")
		f:close()
		if name and name ~= "" then
			config.default_workspace = name
		end
	end

	local last_saved = nil
	wezterm.on("update-status", function(window, pane)
		if pane:get_domain_name() ~= "unix" then
			return
		end
		local ws = window:active_workspace()
		if ws ~= last_saved then
			last_saved = ws
			local out = io.open(last_ws_file, "w")
			if out then
				out:write(ws, "\n")
				out:close()
			end
		end
	end)

	-- Tmux-style persistence
	config.unix_domains = { { name = "unix" } }
	config.default_gui_startup_args = { "connect", "unix" }
end

return M
