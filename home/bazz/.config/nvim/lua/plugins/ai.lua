return {
  -- CopilotChat (includes both chat and completion)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    event = "VeryLazy",
    opts = {
      model = "claude-4.5-sonnet",
      auto_insert_mode = true,
      show_help = true,
      question_header = "## User ",
      answer_header = "## Copilot ",
      window = {
        width = 0.4,
      },
    },
    keys = {
      -- Quick chat
      {
        "<leader>cc",
        function()
          local input = vim.fn.input("Quick Chat: ")
          if input ~= "" then
            require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
          end
        end,
        desc = "CopilotChat - Quick chat",
      },
      -- Show help actions
      {
        "<leader>ch",
        function()
          local actions = require("CopilotChat.actions")
          require("CopilotChat.integrations.fzflua").pick(actions.help_actions())
        end,
        desc = "CopilotChat - Help actions",
      },
      -- Show prompts actions
      {
        "<leader>cp",
        function()
          local actions = require("CopilotChat.actions")
          require("CopilotChat.integrations. fzflua").pick(actions.prompt_actions())
        end,
        desc = "CopilotChat - Prompt actions",
      },
      -- Code related commands
      { "<leader>ce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
      { "<leader>ct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
      { "<leader>cr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
      { "<leader>cR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
      { "<leader>cn", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
      -- Chat commands
      { "<leader>cq", "<cmd>CopilotChatClose<cr>", desc = "CopilotChat - Close chat" },
      { "<leader>cs", "<cmd>CopilotChatStop<cr>", desc = "CopilotChat - Stop current output" },
      { "<leader>cd", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Reset chat" },
      -- Toggle Copilot Chat Vsplit
      { "<leader>ct", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle Vsplit" },
      -- Visual mode mappings
      { "<leader>cv", ":CopilotChatVisual<cr>", mode = "x", desc = "CopilotChat - Open in vertical split" },
      { "<leader>cx", ": CopilotChatInline<cr>", mode = "x", desc = "CopilotChat - Inline chat" },
      -- Model switching
      {
        "<leader>cm",
        "<cmd>CopilotChatModels<cr>",
        desc = "CopilotChat - Select model",
      },
    },
  },
}
