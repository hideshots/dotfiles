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
