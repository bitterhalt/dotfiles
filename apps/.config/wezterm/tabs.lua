local wezterm = require("wezterm")
local titles = require("titles")
local M = {}

function M.setup(config, colors)
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = true
	config.show_new_tab_button_in_tab_bar = false
	-- Set this lower like 1000 if you need update your status (interactive indicators, clocks with seconds etc,)
	config.status_update_interval = 60000

	local tb = colors and colors.tab_bar or nil
	local function pick(state, key, default)
		return (tb and tb[state] and tb[state][key]) or default
	end

	-- Blank real tab titles; custom list is drawn in update-status
	wezterm.on("format-tab-title", function()
		return ""
	end)

	wezterm.on("update-status", function(window, pane)
		local items = {}
		for _, info in ipairs(window:mux_window():tabs_with_info()) do
			local zoomed = titles.is_zoomed(info.tab) and "[Z] " or ""
			local title = zoomed .. wezterm.truncate_right(titles.smart(info.tab:active_pane()), 20)
			local state = info.is_active and "active_tab" or "inactive_tab"

			table.insert(items, { Background = { Color = pick(state, "bg_color", "#888888") } })
			table.insert(items, { Foreground = { Color = pick(state, "fg_color", "#000000") } })
			if info.is_active then
				table.insert(items, { Attribute = { Intensity = "Bold" } })
				table.insert(items, { Attribute = { Italic = true } })
				table.insert(items, { Text = " ✓ " .. title .. " " })
			else
				table.insert(items, { Text = "  " .. (info.index + 1) .. ": " .. title .. "  " })
			end
			table.insert(items, "ResetAttributes")
			table.insert(items, { Text = " " })
		end
		window:set_right_status(wezterm.format(items))
	end)
end

return M
