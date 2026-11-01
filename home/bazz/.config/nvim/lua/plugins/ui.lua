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
        max_name_length = 15, -- follows min_width when omitted
        min_width = 15, -- fixed buffer slot width (columns)
        close_icon = "×", -- empty string hides the close button
        modified_icon = "󰧞",
        exclude_filetypes = {}, -- e.g. { "qf", "help" }
        exclude_buftypes = {}, -- e.g. { "terminal" }
      },
      diagnostics = { enabled = true, error = " ", warn = " " },
      git = { enabled = true, icon = "", max_length = 24 },
      cursor = { enabled = true, separator = " | ", progress = false },
      highlights = {},
    },
    keys = {
      {
        "<leader>bp",
        function()
          require("slimline").toggle_pin()
        end,
        desc = "Toggle buffer pin",
      },
      {
        "<leader>bn",
        function()
          require("slimline").next_pin()
        end,
        desc = "Next pinned buffer",
      },
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
