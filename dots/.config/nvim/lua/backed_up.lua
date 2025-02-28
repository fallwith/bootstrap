-- These are old config snippets kept around in case they're handy
-- again in future

-- 'Envfile' files are Ruby
-- local envfileGroup = vim.api.nvim_create_augroup('envfile', { clear = true })
-- vim.api.nvim_create_autocmd(
--   { "Bufread" },
--   { pattern = "Envfile", command = "set filetype=ruby", group = envfileGroup }
-- )

-- not needed if the colorscheme handles this well itself
-- -- After the colorscheme loads, overwrite DiffChange to use a yellow highlight
-- -- This way added=green, removed=red, and changed=yellow instead of red being
-- -- used for change.
-- vim.api.nvim_create_autocmd("ColorScheme", {
-- 	pattern = "*",
-- 	callback = function()
--     vim.api.nvim_set_hl(0, "DiffChange", { bg="#fffaa0" })
-- 	end,
-- })

-- ctags
-- vim.opt.tags = '.tags'

-- base16 and also transparency
-- { 'chriskempson/base16-vim',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     vim.base16colorspace = 256
--     vim.o.background = 'dark'
--     vim.cmd.colorscheme('base16-tomorrow-night')
--     -- vim.cmd [[
--     --   highlight Normal guibg=none
--     --   highlight NonText guibg=none
--     --   highlight Normal ctermbg=none
--     --   highlight NonText ctermbg=none
--     -- ]]
--   end }

-- unused colorschemes
-- 'zaki/zazen',
-- 'fxn/vim-monochrome',
-- 'arcticicestudio/nord-vim',
-- 'nanotech/jellybeans.vim',
-- 'cocopon/iceberg.vim',
-- 'ldelossa/vimdark',
-- { 'Lokaltog/vim-distinguished', branch = 'develop' },
-- 'fallwith/seabird',
-- 'jaredgorski/fogbell.vim',
-- 'logico/typewriter-vim',
-- 'LuRsT/austere.vim',
-- 'sainnhe/edge',
-- 'sainnhe/sonokai',
-- 'Everblush/everblush.nvim',
-- 'folke/tokyonight.nvim',
-- 'rmehri01/onenord.nvim',
-- 'savq/melange',
-- 'ellisonleao/gruvbox.nvim',
-- 'lunarvim/darkplus.nvim',
-- 'rose-pine/neovim',
-- 'sainnhe/everforest',
-- 'bluz71/vim-nightfly-colors',
-- 'dasupradyumna/midnight.nvim',
-- 'ashen-org/ashen.nvim',
-- 'catppuccin/nvim',
-- 'ribru17/bamboo.nvim',
-- 'mellow-theme/mellow.nvim',
-- 'projekt0n/caret.nvim',
-- 'savq/melange-nvim',
-- 'samharju/serene.nvim',
-- 'xiantang/darcula-dark.nvim',

-- Rust support
-- 'rust-lang/rust.vim',
-- 'simrat39/rust-tools.nvim',

--
-- BEGIN nvim-lint related
--

-- code linting
-- { 'mfussenegger/nvim-lint',
--   config = function()
--     require('lint').linters_by_ft = {
--       ruby = {},
--     }
--   end },

-- local lint = require('lint')
-- lint.linters_by_ft = {
--   ruby = {'rubocop'},
--   rust = {'rust_lint'}
-- }
-- local lint_format = '%E%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
--                  .. 'error:%.%\\{-} %m,%W%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
--                  .. 'warning:%.%\\{-} %m,%C%f:%l %m,%-G,%-G'
--                  .. 'error: aborting %.%#,%-G'
--                  .. 'error: Could not compile %.%#,%E'
--                  .. 'error: %m,%Eerror[E%n]: %m,%-G'
--                  .. 'warning: the option `Z` is unstable %.%#,%W'
--                  .. 'warning: %m,%Inote: %m,%C %#--> %f:%l:%c'

-- rust-vim-lint binary is a shell script as follows:
--
-- #!/usr/bin/env sh

-- test "$1" || exit 1

-- d=$(dirname "$(realpath "$1")")
-- while test "$(echo "$d" | grep -o '/' | wc -l)" -ge 1
-- do
--     test -f "$d/Cargo.toml" && {
--         cd "$d" || exit 1
--         exec cargo check
--     }
--     d=$(echo "$d" | sed s/'\/[^\/]*$'//)
-- done

-- exec clippy-driver "$1"

-- lint.linters.rust_lint = {
--     cmd = 'rust-vim-lint',
--     stdin = false,
--     append_fname = true,
--     args = {},
--     stream = 'both',
--     ignore_exitcode = false,
--     env = nil,
--     parser = require('lint.parser').from_errorformat(lint_format)
-- }
-- vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
--   callback = function()
--     require("lint").try_lint()
--   end,
-- })
-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--   callback = function()
--     require("lint").try_lint()
--   end,
-- })

--
-- END nvim-lint related
--
