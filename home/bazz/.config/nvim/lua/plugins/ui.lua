return {
  -- Theme
  {
    "kepano/flexoki-neovim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme flexoki-dark")
    end,
  },

  -- Mini-statusline
  {
    "echasnovski/mini.statusline",
    event = "BufReadPre",
    version = false,
    config = function()
      require("mini.statusline").setup({
        set_vim_settings = false,
      })
    end,
  },

  --Winbar
  {
    "ramilito/winbar.nvim",
    event = "BufReadPre", -- Alternatively, BufReadPre if we don't care about the empty file when starting with 'nvim'
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("winbar").setup({
        icons = true,
        diagnostics = true,
        buf_modified = true,
        buf_modified_symbol = "Modified",
        dim_inactive = {
          enabled = false,
          highlight = "WinBarNC",
          icons = true, -- whether to dim the icons
          name = true, -- whether to dim the name
        },
        exclude_if = nil,
        filetype_exclude = {
          "help",
          "startify",
          "dashboard",
          "packer",
          "neo-tree",
          "neogitstatus",
          "NvimTree",
          "Trouble",
          "alpha",
          "lir",
          "Outline",
          "spectre_panel",
          "toggleterm",
          "TelescopePrompt",
          "prompt",
        },
      })
    end,
  },
}
