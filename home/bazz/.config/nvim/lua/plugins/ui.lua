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
