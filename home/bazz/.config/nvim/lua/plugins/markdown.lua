return {

  -- Bullets-vim
  {
    "bullets-vim/bullets.vim",
    ft = "markdown",
  },

  -- Markdown-preview
  {
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.fn["mkdp#util#install"]()
    end,
    ft = "markdown",
    keys = {
      { "<C-p>", "<CMD>MarkdownPreviewToggle<CR>", desc = "Toggle Markdown Preview" },
    },
  },

  -- Render-markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("render-markdown").setup({
        heading = {
          enabled = true,
          render_modes = false,
          atx = true,
          setext = true,
          sign = false,
          icons = { "# ", "# ", "# ", "# ", "# ", "# " },
          position = "overlay",
          width = "full",
          left_margin = 0,
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
          border = false,
          border_virtual = false,
          border_prefix = false,
          above = "▄",
          below = "▀",
          backgrounds = {
            "RenderMarkdownH1Bg",
            "RenderMarkdownH2Bg",
            "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg",
            "RenderMarkdownH5Bg",
            "RenderMarkdownH6Bg",
          },
        },
      })
    end,
    keys = {
      { "<leader>mt", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown Render" },
    },
  },

  -- Obsidian-nvim
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      local default_dir = vim.fn.expand("$HOME/Documents/personal/notes")
      local daily_notes_dir = default_dir .. "/daily_note"
      local templates_dir = default_dir .. "/templates"

      if vim.fn.isdirectory(default_dir) == 0 then
        vim.fn.mkdir(default_dir, "p")
      end

      if vim.fn.isdirectory(daily_notes_dir) == 0 then
        vim.fn.mkdir(daily_notes_dir, "p")
      end

      if vim.fn.isdirectory(templates_dir) == 0 then
        vim.fn.mkdir(templates_dir, "p")
      end

      return {
        workspaces = {
          {
            name = "personal",
            path = default_dir,
          },
        },
        daily_notes = {
          folder = "daily_note",
          date_format = "%d-%m-%Y",
          alias_format = "%B %-d, %Y",
          default_tags = { "daily-notes" },
          template = nil,
        },
        templates = {
          folder = "templates",
          date_format = "%a-%d-%m-%Y",
          time_format = "%H:%M",
        },
        ui = {
          enable = false,
        },
      }
    end,
    keys = {
      { "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Open obsidian search menu" },
      { "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Open obsidian search menu" },
      { "<leader>of", "<cmd>ObsidianLinks<CR>", desc = "Open obsidian links menu" },
      { "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Open Obsidian Quick Switch menu" },
      { "<leader>ot", "<cmd>ObsidianTags<CR>", desc = "Open obsidian tag finder" },
      { "<leader>obl", "<Cmd>ObsidianBacklinks<CR>", desc = "Open backlinks menu for current note" },
      { "<leader>or", "<Cmd>ObsidianRename<CR>", desc = "Rename Path" },
    },
  },
}
