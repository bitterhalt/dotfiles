local fn = vim.fn
local data_path = fn.stdpath('data')
local compile_path = data_path..'/site/plugin/packer_compiled.lua'
local install_path = data_path..'/site/pack/packer/start/packer.nvim'
local np_path = vim.fn.expand('~/projects/neoprojet')


    if fn.empty(fn.glob(install_path)) > 0 then
        PACKER_JUST_INSTALLED = fn.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim', install_path
         })
         vim.cmd('packadd packer.nvim')
    end

    local status_ok, packer = pcall(require, 'packer')
        if not status_ok then
        return
    end

    local function get_setup(file_name)
        return string.format('require("setup/%s")', file_name)
    end

    return packer.startup({
        function(use)
	use ('wbthomason/packer.nvim' )
	use ('goolord/alpha-nvim')
	use ('lewis6991/impatient.nvim')
    use ('nvim-lualine/lualine.nvim')
    use ('nvim-tree/nvim-tree.lua')
	use ('RRethy/nvim-base16')
	use ('PotatoesMaster/i3-vim-syntax')
	use ('kovetskiy/sxhkd-vim')
	use ('vim-python/python-syntax')
	use ('ap/vim-css-color')
    use("kyazdani42/nvim-web-devicons")
	use('folke/which-key.nvim')
    use({"nvim-telescope/telescope.nvim",
	tag = "0.1.0",requires = { { "nvim-lua/plenary.nvim" }
        },
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
