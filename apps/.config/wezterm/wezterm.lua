local wezterm = require("wezterm")
local config = wezterm.config_builder()

local colors_file = wezterm.home_dir .. "/.cache/hellwal/colors-wezterm.lua"
local ok, colors = pcall(dofile, colors_file)
if ok then
	config.colors = colors
else
	config.color_scheme = "flexoki-dark"
end

-- Settings
config.automatically_reload_config = true
config.bold_brightens_ansi_colors = false

-- Font
config.font = wezterm.font_with_fallback({
	"Adwaita Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 10.5
config.warn_about_missing_glyphs = false

-- Scrollback & Selection
config.enable_scroll_bar = false
config.selection_word_boundary = " \t\n{}[]()\"'`"

-- Window
config.window_decorations = "NONE"
config.window_close_confirmation = "NeverPrompt"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.adjust_window_size_when_changing_font_size = false

-- Don't dim my panes
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 1.0,
}

-- Cursor
config.default_cursor_style = "SteadyBar"
config.cursor_thickness = "1px"

--- Performance tweaks
config.scrollback_lines = 3500
config.max_fps = 60
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.check_for_updates = false

-- Load all modular components
require("titles").setup()
require("tabs").setup(config, ok and colors or nil)
require("keys").setup(config)
require("persistence").setup(config)

return config
