local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

local function footer()
  local plugins_count = vim.fn.len(vim.fn.globpath("~/.local/share/nvim/site/pack/packer/start", "*", 0, 1))
  return  "   Plugins " .. plugins_count
end

local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
--    [[                                   ]],
--    [[                                   ]],
--    [[          ▀████▀▄▄              ▄█ ]],
--    [[            █▀    ▀▀▄▄▄▄▄    ▄▄▀▀█ ]],
--    [[    ▄        █          ▀▀▀▀▄  ▄▀  ]],
--    [[   ▄▀ ▀▄      ▀▄              ▀▄▀  ]],
--    [[  ▄▀    █     █▀   ▄█▀▄      ▄█    ]],
--    [[  ▀▄     ▀▄  █     ▀██▀     ██▄█   ]],
--    [[   ▀▄    ▄▀ █   ▄██▄   ▄  ▄  ▀▀ █  ]],
--    [[    █  ▄▀  █    ▀██▀    ▀▀ ▀▀  ▄▀  ]],
--    [[   █   █  █      ▄▄           ▄▀   ]],
    "                                                     ",
    "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
    "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
    "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
    "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
    "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
    "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
    "                                                     ",

}
dashboard.section.buttons.val = {
  dashboard.button("fr", "  Recent files", ":Telescope oldfiles <CR>"),
  dashboard.button("ff", "  Find files", ":Telescope find_files <CR>"),
  dashboard.button("fw", "  Find text", ":Telescope live_grep <CR>"),
  dashboard.button("ht", "  Themes  ", ":Telescope colorscheme<CR>"),
  dashboard.button("u", "  Update plugins", "<cmd>PackerSync<CR>"),
  dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
}
-- dashboard.section.header.opts.hl = "Include"
-- dashboard.section.footer.opts.hl = "Include"
dashboard.section.footer.val = footer()
dashboard.opts.opts.noautocmd = false
--vim.cmd[[autocmd User AlphaReady echo 'ready']]
alpha.setup(dashboard.opts)



-- Disable statusline in dashboard
vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function()
    -- store current statusline value and use that
    local old_laststatus = vim.opt.laststatus
    vim.api.nvim_create_autocmd("BufUnload", {
      buffer = 0,
      callback = function()
        vim.opt.laststatus = old_laststatus
      end,
    })
    vim.opt.laststatus = 0
  end,
})
