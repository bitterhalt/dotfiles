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
        position = "bottom", -- "top" moves the buffer list to the tabline
        max_name_length = 15, -- follows min_width when omitted
        min_width = 15, -- fixed buffer slot width (columns)
        close_icon = "×", -- empty string hides the close button
        modified_icon = "󰧞",
        exclude_filetypes = {}, -- e.g. { "qf", "help" }
        exclude_buftypes = {}, -- e.g. { "terminal" }
      },
      diagnostics = {
        enabled = true,
        -- error = "E ",
        -- warn = "W ",
        colors = { error = "#cc241d", warn = "#d79921" },
      },
      git = { enabled = true, icon = "", max_length = 24 },
      cursor = { enabled = true, separator = " | ", progress = false },
      highlights = {
        -- SlimlineActive = { bold = true },
        SlimlinePin = { fg = "#b16286" },
        -- SlimlineSaved = { fg = "#98971a" },
      },
    },
    keys = {
      {
        "<S-l>",
        function()
          require("slimline").next_buffer()
        end,
        desc = "Next buffer",
      },
      {
        "<S-h>",
        function()
          require("slimline").prev_buffer()
        end,
        desc = "Previous buffer",
      },
      {
        "<leader>bm",
        function()
          require("slimline").toggle_position()
        end,
        desc = "Toggle Slimline buffer position",
      },
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
      {
        "<leader>bh",
        function()
          require("slimline").toggle_buffers()
        end,
        desc = "Toggle Slimline buffers",
      },
      {
        "<leader>bd",
        function()
          require("slimline").close_buffer()
        end,
        desc = "Close buffer",
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
