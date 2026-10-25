return {
  -- Mason.nvim
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    dependencies = {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      local mason = require("mason")
      local mason_tool_installer = require("mason-tool-installer")

      mason.setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      mason_tool_installer.setup({
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
          "shfmt",
          "shellcheck",
        },
      })
    end,
  },

  -- Mason LSP Config
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    opts = {
      ensure_installed = {
        "ruff",
        "html",
        "lua_ls",
        "ts_ls",
        "bashls",
      },
      handlers = {
        function(server_name)
          require("lspconfig")[server_name].setup({})
        end,

        ["html"] = function()
          require("lspconfig").html.setup({
            filetypes = { "html", "htmldjango" },
          })
        end,

        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup({
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
              },
            },
          })
        end,
      },
    },
  },

  -- Conform (Formatter)
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          jsonc = { "prettier" },
          qml = { "qmlformat" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          graphql = { "prettier" },
          lua = { "stylua" },
          python = { "ruff_format" },
          sh = { "shfmt" },
        },
        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 500,
        },
      })

      vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },

  -- Nvim-lint
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
        python = { "ruff" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      vim.keymap.set("n", "<leader>li", function()
        lint.try_lint()
      end, { desc = "Trigger linting for current file" })
    end,
  },

  -- Nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    keys = {
      {
        "K",
        vim.lsp.buf.hover,
        desc = "Display information about the symbol under the cursor",
      },
      {
        "gd",
        vim.lsp.buf.definition,
        desc = "Go to definition",
      },
      {
        "crr",
        vim.lsp.buf.code_action,
        mode = { "n", "v" },
        desc = "List available code actions",
      },
      {
        "crn",
        vim.lsp.buf.rename,
        desc = "Renames all references to the symbol under the cursor",
      },
      {
        "<leader>=",
        vim.lsp.buf.format,
        desc = "Formats a buffer using the attached language server",
      },
    },
  },

  -- Nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
      },
      "rafamadriz/friendly-snippets",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      require("luasnip.loaders.from_vscode").lazy_load()

      -- Follow the current Neopywal colorscheme
      vim.api.nvim_set_hl(0, "CmpMenu", { link = "NormalFloat" })
      vim.api.nvim_set_hl(0, "CmpBorder", { link = "NormalFloat" })
      vim.api.nvim_set_hl(0, "CmpSelected", { link = "Visual" })

      local function setup_cmp_colors()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local bg = normal.bg or 0x121212

        local function lighten(color, amount)
          local r = math.min(255, math.floor(bit.rshift(color, 16) + amount))
          local g = math.min(255, math.floor(bit.band(bit.rshift(color, 8), 255) + amount))
          local b = math.min(255, math.floor(bit.band(color, 255) + amount))

          return string.format("#%02x%02x%02x", r, g, b)
        end

        vim.api.nvim_set_hl(0, "CmpMenu", {
          bg = lighten(bg, 18),
          fg = normal.fg,
        })

        vim.api.nvim_set_hl(0, "CmpSelected", {
          bg = lighten(bg, 40),
          fg = normal.fg,
          bold = true,
        })
      end

      setup_cmp_colors()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = setup_cmp_colors,
      })
      cmp.setup({
        completion = {
          completeopt = "menu,menuone,preview,noselect",
        },

        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        window = {
          completion = cmp.config.window.bordered({
            winblend = 0,
            winhighlight = "Normal:CmpMenu,FloatBorder:CmpMenu,CursorLine:CmpSelected,Search:None",
          }),
          documentation = cmp.config.window.bordered({
            winblend = 0,
            winhighlight = "Normal:CmpMenu,FloatBorder:CmpMenu",
          }),
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),

        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  },
}
