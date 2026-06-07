return {
  -- Theme
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("base16-colorscheme").setup({
        base00 = "#101010",
        base01 = "#1c1c1c",
        base02 = "#282828",
        base03 = "#585858",
        base04 = "#888888",
        base05 = "#cecdc3",
        base06 = "#e6e4d9",
        base07 = "#fffcf0",
        base08 = "#d14d41",
        base09 = "#da702c",
        base0A = "#d0a215",
        base0B = "#879a39",
        base0C = "#3aa99f",
        base0D = "#4385be",
        base0E = "#8b7ec8",
        base0F = "#ce5d97",
      })
    end,
  },

  -- {
  --   "kepano/flexoki-neovim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme flexoki-dark")
  --   end,
  -- },

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
  --Bufferline
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "famiu/bufdelete.nvim",
    },
    opts = {
      options = {
        numbers = "none",
        middle_mouse_command = nil,
        indicator_icon = nil,
        indicator = { style = "none" },
        buffer_close_icon = "x",
        modified_icon = "*",
        close_icon = "x",
        left_trunc_marker = "<",
        right_trunc_marker = ">",
        max_name_length = 30,
        max_prefix_length = 30,
        tab_size = 21,
        diagnostics = false, -- | "nvim_lsp" | "coc",
        diagnostics_update_in_insert = false,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = "thin",
        enforce_regular_tabs = true,
        always_show_bufferline = true,
      },
    },
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      local function mode()
        local mode_map = {
          n = "N",
          i = "I",
          v = "V",
          ["\22"] = "VB",
          V = "VL",
          c = "C",
          no = "N",
          s = "S",
          S = "S",
          ic = "I",
          R = "R",
          Rv = "R",
          cv = "C",
          ce = "C",
          r = "R",
          rm = "M",
          ["r?"] = "?",
          ["!"] = "!",
          t = "T",
        }
        return mode_map[vim.fn.mode()] or "[UNKNOWN]"
      end

      require("lualine").setup({
        options = { theme = "auto", section_separators = " ", component_separators = " " },
        sections = {
          lualine_a = { mode },
        },
      })
    end,
  },
}
