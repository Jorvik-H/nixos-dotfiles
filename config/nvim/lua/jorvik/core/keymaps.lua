local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("v", "K", ">+1 <CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "I", "<-2 <CR>gv=gv", { desc = "moves lines up in visual selection" })



-- Movement Remaps
vim.keymap.set( "n", 'j', 'h', { noremap = true, desc = "Move cursor left" })
vim.keymap.set( "n", 'k', 'j', { noremap = true, desc = "Move cursor down" })
vim.keymap.set( "n", 'i', 'k', { noremap = true, desc = "Move cursor up" })
vim.keymap.set( "v", 'j', 'h', { noremap = true, desc = "Move cursor left" })
vim.keymap.set( "v", 'k', 'j', { noremap = true, desc = "Move cursor down" })
vim.keymap.set( "v", 'i', 'k', { noremap = true, desc = "Move cursor up" })
-- 'l' remains 'l', no remap needed unless desired

-- Insert Mode Remaps (Normal mode only)
vim.keymap.set('n', 'h', 'i', { noremap = true, desc = "Enter Insert mode" })
vim.keymap.set('n', 'H', 'I', { noremap = true, desc = "Insert at start of line" })
