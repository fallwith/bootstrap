local lazypath = vim.fn.stdpath('data')..'/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({'git',
                 'clone',
                 '--filter=blob:none',
                 'https://github.com/folke/lazy.nvim.git',
                 '--branch=stable',
                 lazypath})
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- add, remove, swap surroundings like quotes or braces
  --
  --Old text                    Command         New text
  --------------------------------------------------------------------------
  --surr*ound_words             ysiw)           (surround_words)
  --*make strings               ys$"            "make strings"
  --[delete ar*ound me!]        ds]             delete around me!
  --remove <b>HTML t*ags</b>    dst             remove HTML tags
  --'change quot*es'            cs'"            "change quotes"
  --<b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
  --delete(functi*on calls)     dsf             function calls
  { 'kylechui/nvim-surround',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup({})
    end },

  -- run unit tests (nearest, all in file, all in project)
  { 'vim-test/vim-test',
    config = function()
      vim.api.nvim_create_user_command('TN', 'TestNearest', {})
      vim.api.nvim_create_user_command('TF', 'TestFile', {})
    end },

  -- cellular automation animations
  'eandrju/cellular-automaton.nvim',

  -- NeoVim filesystem browsing similar to vinegar
  { 'stevearc/oil.nvim',
    config = function()
      require('oil').setup({
        view_options = {
          show_hidden = true
        }
      })
      vim.keymap.set('n', '-', '<CMD>Oil<CR>')
    end },

  -- code linting
  'mfussenegger/nvim-lint',

  -- tree sitting (https://elevenpond.bandcamp.com/track/watching-trees)
  { 'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require'nvim-treesitter.configs'.setup {
      ensure_installed = { 'bash', 'editorconfig', 'go', 'javascript', 'lua', 'markdown', 'markdown_inline', 'python',
                           'ruby', 'rust', 'typescript', 'yaml' },
      highlight = {
        enable = true,
      },
    }
    end },

  -- treesitter based port of tpope's endwise
  { 'RRethy/nvim-treesitter-endwise',
    dependencies = { 'nvim-treesitter/nvim-treesitter' }},

  -- fuzzy finding
  { 'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/popup.nvim',
                     'nvim-lua/plenary.nvim',
                     'nvim-treesitter/nvim-treesitter' }},

  -- provide context for what structure (method, etc.) the current line is in
  { 'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' }},

  -- view all git diffs in a single nvim session
  { 'sindrets/diffview.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' } },

  -- display Git sigils and things like blame
  { 'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    config = function()
      require('gitsigns').setup()
    end },

  -- GitHub Copilot
  { 'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = {
          enabled = false, -- using nvim-cmp instead
          auto_trigger = false,
        },
        panel = {
          enabled = false, -- using nvim-cmp instead
          auto_trigger = false,
        },
        filetypes = {
          javascript = true,
          lua = true,
          python = true,
          ruby = true,
          rust = true,
          typescript = true,
          ['*'] = false
        },
      })
    end },

  -- GitHub Copilot chat
  { 'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = { 'zbirenbaum/copilot.lua',
                     'nvim-lua/plenary.nvim' },
    build = 'make tiktoken',
    config = function()
      require('CopilotChat').setup({})
    end },

  -- status line
  { 'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons',
                     'AndreM222/copilot-lualine' },
    config = function()
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'gruvbox-material',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
          always_divide_middle = true,
        },
        sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff',
                {
                    'diagnostics',
                    sources = { 'nvim_diagnostic' },
                    symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' }
                }
            },
            lualine_c = { 'filename' },
            lualine_x = { 'copilot', 'encoding', 'fileformat', 'filetype' },
            lualine_y = { 'progress' },
            lualine_z = { 'location' }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { 'filename' },
            lualine_x = { 'location' },
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        extensions = {}
      })
    end },

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
  --   end },

  -- nvim-cmp (Completion Plugin)
  { 'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp',
                     'hrsh7th/cmp-buffer',
                     'hrsh7th/cmp-path',
                     'saadparwaiz1/cmp_luasnip',
                     'onsails/lspkind-nvim',
                     'L3MON4D3/LuaSnip',
                     'zbirenbaum/copilot-cmp',
    },
    config = function()
      require('copilot_cmp').setup()

      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then return false end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match('^%s*$') == nil
      end

      local cmp = require('cmp')
      cmp.setup({
        completion = {
          autocomplete = false,
        },
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = {
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
              fallback()
            end
          end),
          ['<S-Tab>'] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            else
              fallback()
            end
          end),
        },
        sources = {
          { name = 'copilot' },
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
          { name = 'luasnip' },
        },
      })
      cmp.event:on('menu_opened', function()
        vim.b.copilot_suggestion_hidden = true
      end)
      cmp.event:on('menu_closed', function()
        vim.b.copilot_suggestion_hidden = false
      end)
    end },

  -- vimwiki lite
  -- need to run `mkdir ~/.wiki && touch ~/.wiki/index.md`
  -- leader+ww to launch
  -- T to toggle [ ] to [x]
  -- visual select and hit Enter to create a link
  -- ctrl+o to navigate back
  { 'serenevoid/kiwi.nvim',
    opts = { { name = 'wiki', path = vim.fn.expand('~/.wiki') } },
    lazy = true },

  -- colorscheme
  { 'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('gruvbox-material')
    end }
})
