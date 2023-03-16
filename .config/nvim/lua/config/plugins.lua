local fn = vim.fn

-- Automatically install packer
local data_path = fn.stdpath('data')
local compile_path = data_path..'/site/plugin/packer_compiled.lua'
local install_path = data_path..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_JUST_INSTALLED = fn.system({
        'git', 'clone', '--depth', '1',
        'https://github.com/wbthomason/packer.nvim', install_path
    })
    vim.cmd('packadd packer.nvim')
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
      augroup packer_user_config
      autocmd!
      autocmd BufWritePost plugins.lua source <afile> | PackerSync
      augroup end
      ]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

local function get_setup(file_name)
    return string.format('require("setup/%s")', file_name)
end

return packer.startup({
    function(use)
        use ('PotatoesMaster/i3-vim-syntax')
        use ('moll/vim-bbye')
        use ('RRethy/nvim-base16')
        use ('ap/vim-css-color')
        use ('akinsho/bufferline.nvim')
        use ('goolord/alpha-nvim')
        use ('kovetskiy/sxhkd-vim')
        use ('lewis6991/impatient.nvim')
        use ('wbthomason/packer.nvim' )
        use ('folke/which-key.nvim')
        use ('nvim-lualine/lualine.nvim')
        use ('nvim-tree/nvim-tree.lua')
        use ('kyazdani42/nvim-web-devicons')
        use ('nvim-treesitter/nvim-treesitter')
        use ('luisiacc/gruvbox-baby')
        use({"nvim-telescope/telescope.nvim",
            tag = "0.1.0",requires = { { "nvim-lua/plenary.nvim" }
            },
        })

        -- LSP-zero
        use {
            'VonHeikemen/lsp-zero.nvim',
            branch = 'v1.x',
            requires = {
                -- LSP Support
                {'neovim/nvim-lspconfig'},
                {'williamboman/mason.nvim'},
                {'williamboman/mason-lspconfig.nvim'},

                -- Autocompletion
                {'hrsh7th/nvim-cmp'},
                {'hrsh7th/cmp-buffer'},
                {'hrsh7th/cmp-path'},
                {'saadparwaiz1/cmp_luasnip'},
                {'hrsh7th/cmp-nvim-lsp'},
                {'hrsh7th/cmp-nvim-lua'},

                -- Snippets
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

        if PACKER_JUST_INSTALLED then
            vim.api.nvim_create_autocmd('User PackerComplete', {
                command = 'qa!',
            })
            packer.sync()
        end

        pcall(require, 'impatient')
    end,
    config = {
        compile_path = compile_path,
        display = {
            open_fn = require('packer.util').float,
        },
        profile = {
            enabled = true,
        },
    },
})
