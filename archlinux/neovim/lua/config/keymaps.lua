vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap.set

-- General keymaps
keymap("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlighting" })

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Buffer navigation
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Decrease indent" })
keymap("v", ">", ">gv", { desc = "Increase indent" })

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })
