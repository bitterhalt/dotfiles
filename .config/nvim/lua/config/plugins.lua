local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer()

local status, packer = pcall(require, "packer")
if not status then
    return
end

vim.cmd([[
    augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup END
]])

return packer.startup(function(use)

    use ('goolord/alpha-nvim')
    use ('moll/vim-bbye')
    use ('RRethy/nvim-base16')
    use ('ap/vim-css-color')
    use ('akinsho/bufferline.nvim')
    use ('wbthomason/packer.nvim' )
    use ('folke/which-key.nvim')
    use ('nvim-lualine/lualine.nvim')
    use ('nvim-tree/nvim-tree.lua')
    use ('kyazdani42/nvim-web-devicons')
    use ('nvim-treesitter/nvim-treesitter')
    use ('navarasu/onedark.nvim')
    use({"nvim-telescope/telescope.nvim",
        tag = "0.1.x",requires = { { "nvim-lua/plenary.nvim" }
        },
    })

    -- LSP-Zero
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'dev-v3',
        requires = {
            {'neovim/nvim-lspconfig'},
            {
                'williamboman/mason.nvim',
                run = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            {'williamboman/mason-lspconfig.nvim'},
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-path'},
            {'saadparwaiz1/cmp_luasnip'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/cmp-nvim-lua'},
            {'L3MON4D3/LuaSnip'},
            {'rafamadriz/friendly-snippets'},
        }
    }

    use {'vimwiki/vimwiki',
        config = function()
            vim.g.vimwiki_list = {
                {
                    path = '~/Documents/.vimwiki/',
                    syntax = 'markdown',
                    ext = '.md',
                }
            }
        end
    }

    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })

    if packer_bootstrap then
        require("packer").sync()
    end
end)
