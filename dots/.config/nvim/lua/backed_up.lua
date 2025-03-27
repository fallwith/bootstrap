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



-- BEGIN Copilot

  -- -- GitHub Copilot
  -- { 'zbirenbaum/copilot.lua',
  --   cmd = 'Copilot',
  --   event = 'InsertEnter',
  --   config = function()
  --     require('copilot').setup({
  --       suggestion = {
  --         enabled = false, -- using nvim-cmp instead
  --         auto_trigger = false,
  --       },
  --       panel = {
  --         enabled = false, -- using nvim-cmp instead
  --         auto_trigger = false,
  --       },
  --       filetypes = {
  --         javascript = true,
  --         lua = true,
  --         python = true,
  --         ruby = true,
  --         rust = true,
  --         typescript = true,
  --         ['*'] = false
  --       },
  --     })
  --   end },
  --
  -- -- GitHub Copilot chat
  -- { 'CopilotC-Nvim/CopilotChat.nvim',
  --   dependencies = { 'zbirenbaum/copilot.lua',
  --                    'nvim-lua/plenary.nvim' },
  --   build = 'make tiktoken',
  --   config = function()
  --     require('CopilotChat').setup({})
  --   end },

-- lines to add to lualine plugin config:
-- 'AndreM222/copilot-lualine' },
-- lualine_x = { 'copilot', 'encoding', 'fileformat', 'filetype' },

-- lines to add to nvim-cmp plugin config:
-- 'zbirenbaum/copilot-cmp',
-- require('copilot_cmp').setup()
-- sources = {
-- { name = 'copilot' },
      -- cmp.event:on('menu_opened', function()
      --   vim.b.copilot_suggestion_hidden = true
      -- end)
      -- cmp.event:on('menu_closed', function()
      --   vim.b.copilot_suggestion_hidden = false
      -- end)

-- END Copilot

-- BEGIN Rust linting with nvim-lint
-- local lint = require('lint')
-- lint.linters_by_ft = {
--   ruby = {'rubocop'},
--   rust = {'rust_lint'}
-- }
--
-- local lint_format = '%E%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
--                  .. 'error:%.%\\{-} %m,%W%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
--                  .. 'warning:%.%\\{-} %m,%C%f:%l %m,%-G,%-G'
--                  .. 'error: aborting %.%#,%-G'
--                  .. 'error: Could not compile %.%#,%E'
--                  .. 'error: %m,%Eerror[E%n]: %m,%-G'
--                  .. 'warning: the option `Z` is unstable %.%#,%W'
--                  .. 'warning: %m,%Inote: %m,%C %#--> %f:%l:%c'
--
-- -- rust-vim-lint binary is a shell script as follows:
-- --
-- -- #!/usr/bin/env sh
-- --
-- -- test "$1" || exit 1
-- --
-- -- d=$(dirname "$(realpath "$1")")
-- -- while test "$(echo "$d" | grep -o '/' | wc -l)" -ge 1
-- -- do
-- --     test -f "$d/Cargo.toml" && {
-- --         cd "$d" || exit 1
-- --         exec cargo check
-- --     }
-- --     d=$(echo "$d" | sed s/'\/[^\/]*$'//)
-- -- done
-- --
-- -- exec clippy-driver "$1"
--
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
-- END Rust linting with nvim-lint

-- LSP usage
--
-- gd = go to definition
-- K  = show documentation
-- gr = rename
-- gi = go to implementation
-- gD = go to declaration
-- gI = go to type definition
-- gR = references
-- g0 = go to previous diagnostic
-- g1 = go to next diagnostic
-- g2 = show line diagnostics
-- g3 = show workspace diagnostics
-- g4 = show all diagnostics
-- g5 = show code actions
-- g6 = show code actions for line
-- g7 = show code actions for range
-- g8 = show code actions for workspace
-- g9 = show code actions for file
-- g- = show code actions for buffer
-- g= = show code actions for line
-- g+ = show code actions for range
-- g* = show code actions for workspace
-- g/ = show code actions for file
-- g? = show code actions for buffer
-- g! = show code actions for line
-- g@ = show code actions for range
-- g# = show code actions for workspace
-- g$ = show code actions for file
-- g% = show code actions for buffer
-- g^ = show code actions for line
-- g& = show code actions for range
-- g~ = show code actions for workspace
-- g` = show code actions for file
-- { 'neovim/nvim-lspconfig',
--   config = function()
--     local lspconfig = require('lspconfig')
--     lspconfig.solargraph.setup { autostart = true,
--                                  completion = true }
--
--     -- ruby_lsp needs Ruby v3+
--     -- lspconfig.ruby_lsp.setup {
--     --   init_options = {
--     --     formatter = 'standard',
--     --     linters = { 'standard' },
--     --     addonSettings = {
--     --       ['Ruby LSP Rails'] = {
--     --         enablePendingMigrationsPrompt = false,
--     --       },
--     --   },
--     -- }
--     lspconfig.rust_analyzer.setup { autostart = true }
--     lspconfig.ts_ls.setup { autostart = true }
--
--     vim.api.nvim_create_user_command('LSPFormat', ':lua vim.lsp.buf.format()<CR>', {})
--   end


-- -- nvim-cmp (Completion Plugin)
-- { 'hrsh7th/nvim-cmp',
--   dependencies = { 'hrsh7th/cmp-nvim-lsp',
--                    'hrsh7th/cmp-buffer',
--                    'hrsh7th/cmp-path',
--                    'saadparwaiz1/cmp_luasnip',
--                    'onsails/lspkind-nvim',
--                    'L3MON4D3/LuaSnip' },
--   config = function()
--
--     local has_words_before = function()
--       if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then return false end
--       local line, col = unpack(vim.api.nvim_win_get_cursor(0))
--       return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match('^%s*$') == nil
--     end
--
--     local cmp = require('cmp')
--     cmp.setup({
--       completion = {
--         autocomplete = false,
--       },
--       snippet = {
--         expand = function(args)
--           require('luasnip').lsp_expand(args.body)
--         end,
--       },
--       mapping = {
--         ['<C-Space>'] = cmp.mapping.complete(),
--         ['<CR>'] = cmp.mapping.confirm({ select = true }),
--         ['<Tab>'] = vim.schedule_wrap(function(fallback)
--           if cmp.visible() and has_words_before() then
--             cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
--           else
--             fallback()
--           end
--         end),
--         ['<S-Tab>'] = vim.schedule_wrap(function(fallback)
--           if cmp.visible() and has_words_before() then
--             cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
--           else
--             fallback()
--           end
--         end),
--       },
--       sources = {
--         { name = 'nvim_lsp' },
--         { name = 'buffer' },
--         { name = 'path' },
--         { name = 'luasnip' },
--       },
--     })
--   end },
