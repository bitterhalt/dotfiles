return {

  -- Tfm (file manager)
  {
    "rolv-apneseth/tfm.nvim",
    lazy = false,
    cmd = "Tfm",
    opts = {
      file_manager = "lf",
      replace_netrw = true,
      enable_cmds = true,
      ui = {
        border = "rounded",
        height = 1,
        width = 1,
        x = 0.5,
        y = 0.5,
      },
    },
    keys = {
      {
        "<leader>e",
        "<Cmd>Tfm<CR>",
        desc = "Open file manager",
      },
    },
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

  -- Which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      icons = {
        breadcrumb = ">",
        separator = ">",
        group = "+",
      },
    },
  },

  -- Noice
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        routes = {
          {
            filter = {
              event = "msg_show",
              find = "written",
            },
            opts = { skip = true },
          },
        },
      })
    end,
  },

  -- FzfLua
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    config = function()
      require("fzf-lua").setup({
        { "default", "hide" },

        winopts = {
          fullscreen = false,
        },

        grep = {
          fzf_opts = {
            ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-grep-history",
          },
        },
      })
    end,

    keys = {
      { "<leader>ff", "<Cmd>FzfLua files<CR>", desc = "Search files" },
      { "<leader><tab>", "<Cmd>FzfLua buffers<CR>", desc = "Search buffers" },

      { "<leader>fw", "<Cmd>FzfLua live_grep resume=true<CR>", desc = "Resume live grep" },
      { "<leader>fW", "<Cmd>FzfLua live_grep<CR>", desc = "New live grep" },

      { "<leader>fr", "<Cmd>FzfLua oldfiles<CR>", desc = "Search recent files" },
      { "<leader>fz", "<Cmd>FzfLua zoxide<CR>", desc = "List recent directories" },
    },
  },

  -- Trouble
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>fd",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>fX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  -- lazygit.nvim
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
}
