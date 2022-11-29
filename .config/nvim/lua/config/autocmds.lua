-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
    command = '%s/\\s\\+$//e',
})

-- Show diagnostics on dialog on cursor hover
vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
        vim.diagnostic.open_float({ focusable = false })
    end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank(
            { igroup="IncSearch", timeout=150, on_visual=true }
        )
    end,
})

