require 'plugins'
require 'options'
require 'mappings'

-- remove the editor trimmings from terminal splits
vim.api.nvim_command [[autocmd TermOpen * setlocal nonumber norelativenumber nospell]]

-- git commits
local gitCommitGroup = vim.api.nvim_create_augroup('gitcommit', { clear = true })
vim.api.nvim_create_autocmd(
  "Filetype",
  { pattern = "gitcommit",
    command = "setlocal spell textwidth=72 colorcolumn=50,72",
    group = gitCommitGroup }
)

-- 'Envfile' files are Ruby
local envfileGroup = vim.api.nvim_create_augroup('envfile', { clear = true })
vim.api.nvim_create_autocmd(
  { "Bufread" },
  { pattern = "Envfile", command = "set filetype=ruby", group = envfileGroup }
)
