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

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = { theme = "auto", section_separators = "", component_separators = "" },
      })
    end,
  },
}
