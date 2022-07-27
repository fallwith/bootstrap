require 'plugins'
require 'options'
require 'mappings'
require 'lsp'
require 'cmp_config'
require 'octo_config'

-- colorscheme
vim.cmd [[
  let g:edge_style = 'aura'
  colorscheme edge
]]

-- remove the editor trimmings from terminal splits
vim.api.nvim_command [[autocmd TermOpen * setlocal nonumber norelativenumber nospell]]

-- git commits
local gitCommitGroup = vim.api.nvim_create_augroup('gitcommit', { clear = true })
vim.api.nvim_create_autocmd(
  "Filetype",
  { pattern = "gitcommit",
    command = "setlocal spell textwidth=72 colorcolumn=50,72" }
)

-- null-ls
require('null-ls').setup {
  debug = false,
  sources = {
    require('null-ls').builtins.diagnostics.rubocop,
  },
}
