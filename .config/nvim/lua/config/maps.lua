local function map(m, k,v)
	vim.keymap.set(m, k, v, { silent = true })
end

-- Keybindings for telescope
map("n", "<leader>ff", "<CMD>Telescope find_files <CR>")
map("n", "<leader>fa", "<CMD>Telescope find_files hidden=true <CR>")
map("n", "<leader>fb", "<CMD>Telescope buffers<cr>")
map("n", "<leader>fh", "<CMD>Telescope help_tags<CR>")
map("n", "<leader>fr", "<CMD>Telescope oldfiles<CR>")
map("n", "<leader>fw", "<CMD>Telescope live_grep<CR>")
map("n", "<leader>ht", "<CMD>Telescope colorscheme<CR>")
-- move between buffers
map("n", "<S-l>", "<CMD>:bnext<CR>")
map("n", "<S-h>", "<CMD>:bprevious<CR>")

-- Move around splits using Ctrl + {h,j,k,l}
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Resize with arrows
map("n", "<C-Up>", ":resize -2<CR>")
map("n", "<C-Down>", ":resize +2<CR>")
map("n", "<C-Left>", ":vertical resize -2<CR>")
map("n", "<C-Right>", ":vertical resize +2<CR>")

-- move highlighted line(s) above/below"
map('v', 'K', ':m \'<-2<CR>gv=gv')
map('v', 'J', ':m \'>+1<CR>gv=gv')

-- Close all windows and exit from Neovim with <leader>
map('n', '<leader>q', ':qa!<CR>')

-- Clear search highlighting with <leader> and c
map('n', '<C-c>', ':nohl<CR>')
-- Save file
map ('n', "<C-s>", "<CMD>:w<CR>")

-- Change split orientation
map('n', '<leader>tk', '<C-w>t<C-w>K') -- change vertical to horizontal
map('n', '<leader>th', '<C-w>t<C-w>H') -- change horizontal to vertical

-- Toggle nvim-tree
map('n', '<C-n>',     "<CMD>NvimTreeToggle<CR>")

-- Close buffers
map("n", "<S-q>", "<cmd>Bdelete!<CR>")

-- Markdown Preview toggle
map("n", "<C-p>", "<cmd>MarkdownPreviewToggle<CR>")

-- replace word
map("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
