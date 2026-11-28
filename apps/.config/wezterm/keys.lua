local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function only_in_unix(action)
	return wezterm.action_callback(function(window, pane)
		if pane:get_domain_name() == "unix" then
			window:perform_action(action, pane)
		end
	end)
end

local function workspace_has_windows(name)
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		if mux_win:get_workspace() == name then
			return true
		end
	end
	return false
end

function M.setup(config)
	config.keys = {
		-- Zoom: toggle the focused pane to fill the tab (tmux-style)
		{ key = "z", mods = "ALT", action = act.TogglePaneZoomState },

		-- Move focus between panes
		{ key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },

		-- Splits
		{ key = ",", mods = "CTRL", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = ".", mods = "CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "Enter", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

		-- Reset font size
		{ key = "0", mods = "CTRL", action = act.ResetFontSize },

		-- Search mode
		{ key = "s", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },

		-- Action launcher
		{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },

		-- Close current pane without asking
		{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

		-- Jump straight to tab 1-5
		{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
		{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
		{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
		{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
		{ key = "5", mods = "ALT", action = act.ActivateTab(4) },

		-- Previous / next tab (arrows & vim keys)
		{ key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
		{ key = "RightArrow", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },
		{ key = "h", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
		{ key = "l", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },

		-- Swap panes
		{ key = "f", mods = "CTRL|SHIFT", action = act.RotatePanes("Clockwise") },
		{ key = "b", mods = "CTRL|SHIFT", action = act.RotatePanes("CounterClockwise") },
		{ key = "s", mods = "ALT", action = act.PaneSelect({ mode = "SwapWithActive" }) },

		-- Workspaces: cycle forward
		{ key = "PageUp", mods = "CTRL|SHIFT", action = only_in_unix(act.SwitchWorkspaceRelative(1)) },
		{ key = "PageDown", mods = "CTRL|SHIFT", action = only_in_unix(act.SwitchWorkspaceRelative(-1)) },

		-- Workspace selector - only active in "unix" domain)
		{
			key = "w",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				if pane:get_domain_name() ~= "unix" then
					return
				end

				local current = window:active_workspace()
				local choices = { { id = current, label = current .. " (current)" } }
				for _, name in ipairs(wezterm.mux.get_workspace_names()) do
					if name ~= current then
						table.insert(choices, { id = name, label = name })
					end
				end

				window:perform_action(
					act.InputSelector({
						title = "Workspaces",
						choices = choices,
						fuzzy = true,
						fuzzy_description = "Switch workspace: ",
						action = wezterm.action_callback(function(inner_window, inner_pane, id)
							if id then
								inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
							end
						end),
					}),
					pane
				)
			end),
		},

		-- Rename current workspace (only active in "unix" domain)
		{
			key = "r",
			mods = "ALT",
			action = only_in_unix(act.PromptInputLine({
				description = "Rename current workspace:",
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
					end
				end),
			})),
		},

		-- Create / switch to named workspace (only active in "unix" domain)
		{
			key = "a",
			mods = "CTRL|SHIFT",
			action = only_in_unix(act.PromptInputLine({
				description = "Give name for new workspace:",
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end
				end),
			})),
		},

		-- Switch to monitoring workspace (btop inside "unix" domain).
		{
			key = "m",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				if pane:get_domain_name() ~= "unix" then
					return
				end

				if not workspace_has_windows("monitoring") then
					window:perform_action(
						act.SwitchToWorkspace({
							name = "monitoring",
							spawn = {
								domain = { DomainName = "unix" },
								args = { "btop" },
							},
						}),
						pane
					)
				else
					window:perform_action(act.SwitchToWorkspace({ name = "monitoring" }), pane)
				end
			end),
		},

		-- Dotfiles workspace (lazy build, reused once it has a window)
		{
			key = "d",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				if pane:get_domain_name() ~= "unix" then
					return
				end

				local dir = wezterm.home_dir .. "/Documents/projects/dotfiles"

				if not workspace_has_windows("dotfiles") then
					local _, left_pane, mux_win = wezterm.mux.spawn_window({
						domain = { DomainName = "unix" },
						cwd = dir,
						args = { "opencode" },
					})
					mux_win:set_workspace("dotfiles")

					left_pane:split({
						direction = "Right",
						cwd = dir,
						args = { "nvim" },
					})
				end

				window:perform_action(act.SwitchToWorkspace({ name = "dotfiles" }), pane)
			end),
		},
	}
end

return M
