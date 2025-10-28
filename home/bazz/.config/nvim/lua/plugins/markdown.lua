return {
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
          custom = {},
        },
        vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { fg = "#24837B", bold = true }),
        vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { fg = "#A02F6F", bold = true }),
        vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { fg = "#205EA6", bold = true }),
        vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { fg = "#AD8301", bold = true }),
        vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { fg = "#66800B", bold = true }),
        vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { fg = "#AF3029", bold = true }),
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
      -- Default directory, if no path is provided
      local default_dir = vim.fn.expand("$HOME/Documents/personal/notes")
      local daily_notes_dir = default_dir .. "/daily_note"
      local templates_dir = default_dir .. "/templates"

      -- Check if the default directory exists, if not, create it
      if vim.fn.isdirectory(default_dir) == 0 then
        vim.fn.mkdir(default_dir, "p")
      end

      -- Check if the daily notes directory exists, if not, create it
      if vim.fn.isdirectory(daily_notes_dir) == 0 then
        vim.fn.mkdir(daily_notes_dir, "p")
      end

      -- Check if the templates directory exists, if not, create it
      if vim.fn.isdirectory(templates_dir) == 0 then
        vim.fn.mkdir(templates_dir, "p")
      end

      return {
        workspaces = {
          {
            -- Default to this directory, if no path is provided by the user
            name = "personal",
            -- Replace the default_dir, if you want to use different path
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
          -- Let markview.nvim handle syntax
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
