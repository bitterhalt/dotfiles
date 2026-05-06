return {
  -- Treesitter
  {
    "romus204/tree-sitter-manager.nvim",
    dependencies = {}, -- tree-sitter CLI must be installed system-wide
    config = function()
      require("tree-sitter-manager").setup({
        -- ensure_installed = {}, -- list of parsers to install at the start of a neovim session
        -- border = nil, -- border style for the window (e.g. "rounded", "single"), if nil, use the default border style defined by 'vim.o.winborder'. See :h 'winborder' for more info.
        auto_install = true, -- if enabled, install missing parsers when editing a new file
        -- highlight = true, -- treesitter highlighting is enabled by default
        -- languages = {}, -- override or add new parser sources
        -- parser_dir = vim.fn.stdpath("data") .. "/site/parser",
        -- query_dir = vim.fn.stdpath("data") .. "/site/queries",
      })
    end,
  },

  -- NvChad/nvim-colorizer
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        opts = {
          user_default_options = { names = false },
          filetypes = {
            "*",
            "!lazy",
          },
        },
      })
    end,
  },

  -- Nnvim-autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        disable_filetype = { "TelescopePrompt", "vim" },
      })
    end,
  },

  -- Blankline-nvim
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      exclude = {
        filetypes = { "help", "alpha", "dashboard", "Trouble", "lazy", "neo-tree" },
      },
    },
    event = "VeryLazy",
  },
}
