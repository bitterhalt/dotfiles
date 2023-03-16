local lsp = require('lsp-zero').preset({
  name = 'recommended',
  set_lsp_keymaps = true,
  manage_nvim_cmp = true,
})
lsp.ensure_installed({
  'tsserver',
})
-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

lsp.setup()
vim.diagnostic.config({
    virtual_text = true
})


