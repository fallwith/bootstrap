require 'plugins'
require 'options'
require 'mappings'

-- colorscheme
vim.cmd.colorscheme "rose-pine"

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

local lint = require('lint')
lint.linters_by_ft = {
  ruby = {'rubocop'},
  rust = {'rust_lint'}
}
local lint_format = '%E%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
                 .. 'error:%.%\\{-} %m,%W%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
                 .. 'warning:%.%\\{-} %m,%C%f:%l %m,%-G,%-G'
                 .. 'error: aborting %.%#,%-G'
                 .. 'error: Could not compile %.%#,%E'
                 .. 'error: %m,%Eerror[E%n]: %m,%-G'
                 .. 'warning: the option `Z` is unstable %.%#,%W'
                 .. 'warning: %m,%Inote: %m,%C %#--> %f:%l:%c'

lint.linters.rust_lint = {
    cmd = 'rust-vim-lint',
    stdin = false,
    append_fname = true,
    args = {},
    stream = 'both',
    ignore_exitcode = false,
    env = nil,
    parser = require('lint.parser').from_errorformat(lint_format)
}
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
