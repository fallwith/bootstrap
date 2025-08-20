-- use jk for Esc
vim.api.nvim_set_keymap("i", "jk", "<Esc>", { noremap = true })
vim.api.nvim_set_keymap("v", "jk", "<Esc>", { noremap = true })

-- flip ; and :
vim.api.nvim_set_keymap("n", ";", ":", { noremap = true })
vim.api.nvim_set_keymap("n", ":", ";", { noremap = true })
vim.api.nvim_set_keymap("v", ";", ":", { noremap = true })
vim.api.nvim_set_keymap("v", ":", ";", { noremap = true })

-- terminal
--   * launch terminal with <leader>t
--   * C-o to switch back (from terminal mode) to normal mode
vim.api.nvim_set_keymap("n", "<leader>t", ":terminal<CR>", { noremap = true })
vim.api.nvim_set_keymap("t", "<C-o>", "<C-\\><C-n>", { noremap = true })

-- clear search highlighting
vim.api.nvim_set_keymap("n", "<leader>/", ":nohlsearch<CR>", { noremap = true, silent = true })

-- vertical/horizontal splits
vim.api.nvim_set_keymap("n", "<leader>v", ":below vnew<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>h", ":below new<CR>", { noremap = true })

-- instead of ctrl+w, letter, just do ctrl+letter
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w><C-h>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w><C-j>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w><C-k>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w><C-l>", { noremap = true })

-- immediately reselect text after indenting/outdenting
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true })
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true })

-- system clipboard yank/put helpers
vim.api.nvim_set_keymap("n", "<leader>yy", '"+yy', { noremap = true })
vim.api.nvim_set_keymap("v", "<leader>y", '"+y', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>p", '"+p', { noremap = true })
vim.api.nvim_set_keymap("v", "<leader>p", '"+p', { noremap = true })

-- diagnostics (when on an underlined bit of text)
vim.keymap.set("n", "<Leader>x", vim.diagnostic.open_float, { desc = "Show diagnostics popup" })

-- copy current file path to clipboard
vim.api.nvim_create_user_command("CP", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Copy current file path to clipboard" })

-- display current lualine theme
vim.api.nvim_create_user_command("Luatheme", function()
  print("Lualine theme: " .. (vim.g.lualine_theme or "unknown"))
end, { desc = "Display current lualine theme" })
