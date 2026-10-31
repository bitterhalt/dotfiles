return {

  -- Theme
  {
    "bitterhalt/neohellwal.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("neohellwal").setup()
      vim.cmd.colorscheme("neohellwal")
    end,
  },

  -- Vim-tmux-navigator
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Slimline
  {
    "bitterhalt/nvim.slimline",
    main = "slimline",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      icons = true,
      encoding = { enabled = true },
      recording = { icon = "REC" },
      mode = {
        enabled = true,
        labels = {}, -- Neovim mode codes, e.g. { n = "NORMAL", i = "INSERT" }
      },
      buffers = {
        enabled = true,
        max_name_length = 20,
        close_icon = "×", -- empty string hides the close button
        modified_icon = "󰧞",
        exclude_filetypes = {}, -- e.g. { "qf", "help" }
        exclude_buftypes = {}, -- e.g. { "terminal" }
      },
      diagnostics = { enabled = true, error = "E!", warn = "W!" },
      git = { enabled = true, icon = "", max_length = 24 },
      cursor = { enabled = true, separator = " | ", progress = false },
      highlights = {},
    },
  },
}
--   {
--     dir = "/home/bazz/Documents/projects/nvim.slimline",
--     name = "slimline",
--     main = "slimline",
--     lazy = false,
--     dependencies = {
--       "nvim-tree/nvim-web-devicons",
--       "famiu/bufdelete.nvim",
--     },
--     opts = {},
--   },
-- }
