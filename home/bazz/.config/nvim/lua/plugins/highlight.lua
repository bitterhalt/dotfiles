return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-context" },
    branch = "master", -- TODO: MOVE TO MAIN BRANCH https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file
    main = "nvim-treesitter.configs",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "html" },
      auto_install = true,
      ignore_install = { "latex" },
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
      },
    },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
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
