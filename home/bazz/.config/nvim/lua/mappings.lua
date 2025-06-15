vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Remove highlights
vim.keymap.set("n", "<Esc>", "<Cmd>noh<CR>")

-- move between buffers
vim.keymap.set("n", "<S-l>", "<CMD>:bnext<CR>")
vim.keymap.set("n", "<S-h>", "<CMD>:bprevious<CR>")

-- Move around splits using Ctrl + {h,j,k,l}
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Resize with arrows
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>")
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>")
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>")

-- move highlighted line(s) above/below"
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- Close all windows and exit from Neovim with <leader>
vim.keymap.set("n", "<leader>q", ":qa!<CR>")

-- Save file
vim.keymap.set("n", "<C-s>", "<CMD>:w<CR>")

-- Change split orientation
vim.keymap.set("n", "<leader>tk", "<C-w>t<C-w>K") -- change vertical to horizontal
vim.keymap.set("n", "<leader>th", "<C-w>t<C-w>H") -- change horizontal to vertical

-- replace word
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Update Lazy plugins
vim.keymap.set("n", "<leader>ls", "<CMD>Lazy sync<CR>")

-- Tabs
vim.keymap.set("n", "<leader>bt", "<CMD>:tab sball<CR>")
vim.keymap.set("n", "<leader>bc", "<CMD>:tabo<CR>")

-- Close buffers
vim.keymap.set("n", "<S-q>", "<cmd>bdelete<CR>")
