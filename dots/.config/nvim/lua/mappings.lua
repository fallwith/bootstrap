-- use a comma for the leader key
vim.g.mapleader = ','

-- use jk for Esc
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', {noremap = true})
vim.api.nvim_set_keymap('v', 'jk', '<Esc>', {noremap = true})

-- flip ; and :
vim.api.nvim_set_keymap('n', ';', ':', {noremap = true})
vim.api.nvim_set_keymap('n', ':', ';', {noremap = true})
vim.api.nvim_set_keymap('v', ';', ':', {noremap = true})
vim.api.nvim_set_keymap('v', ':', ';', {noremap = true})

-- terminal
--   * launch terminal with <leader>t
--   * C-o to switch back (from terminal mode) to normal mode
vim.api.nvim_set_keymap('n', '<leader>t', ':terminal<CR>', {noremap = true})
vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-n>', {noremap = true})

-- clear search highlighting
vim.api.nvim_set_keymap('n', '<leader>/', ':nohlsearch<CR>', {noremap = true, silent = true})

-- vertical/horizontal splits
vim.api.nvim_set_keymap('n', '<leader>v', ':below vnew<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>h', ':below new<CR>', {noremap = true})

-- instead of ctrl+w, letter, just do ctrl+letter
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w><C-h>', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w><C-j>', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w><C-k>', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w><C-l>', {noremap = true})

-- telescope
vim.api.nvim_set_keymap('n', '<leader>f', "<cmd>lua require('telescope.builtin').find_files()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>g', "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>b', "<cmd>lua require('telescope.builtin').buffers()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fh', "<cmd>lua require('telescope.builtin').help_tags()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>ft', "<cmd>lua require('telescope.builtin').tags()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fc', "<cmd>lua require('telescope.builtin').colorscheme()<cr>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>fs', "<cmd>lua require('telescope.builtin').spell_suggest()<cr>", {noremap = true})

-- immediately reselect text after indenting/outdenting
vim.api.nvim_set_keymap('v', '<', '<gv', {noremap = true})
vim.api.nvim_set_keymap('v', '>', '>gv', {noremap = true})

-- system clipboard yank/put helpers
vim.api.nvim_set_keymap('n', '<leader>yy', '"+yy', {noremap = true})
vim.api.nvim_set_keymap('v', '<leader>y', '"+y', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>p', '"+p', {noremap = true})
vim.api.nvim_set_keymap('v', '<leader>p', '"+p', {noremap = true})

-- diffview
vim.api.nvim_set_keymap('n', '<leader>d', ':DiffviewOpen<CR>', {noremap = true})
