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
  { 'mfussenegger/nvim-lint',
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        ruby = {'rubocop'}
      }
      vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufWritePost' }, {
        callback = function()
          local lint_status, lint = pcall(require, 'lint')
            if lint_status then
              lint.try_lint()
            end
        end,
      })
    end },

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

  -- -- status line
  -- { 'nvim-lualine/lualine.nvim',
  --   dependencies = { 'nvim-tree/nvim-web-devicons' },
  --   config = function()
  --     require('lualine').setup({
  --       options = {
  --         icons_enabled = true,
  --         theme = 'gruvbox-material',
  --         section_separators = { left = '', right = '' },
  --         component_separators = { left = '', right = '' },
  --         always_divide_middle = true,
  --       },
  --       sections = {
  --           lualine_a = { 'mode' },
  --           lualine_b = { 'branch', 'diff',
  --               {
  --                   'diagnostics',
  --                   sources = { 'nvim_diagnostic' },
  --                   symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' }
  --               }
  --           },
  --           lualine_c = { 'filename' },
  --           lualine_y = { 'progress' },
  --           lualine_z = { 'location' }
  --       },
  --       inactive_sections = {
  --           lualine_a = {},
  --           lualine_b = {},
  --           lualine_c = { 'filename' },
  --           lualine_x = { 'location' },
  --           lualine_y = {},
  --           lualine_z = {}
  --       },
  --       tabline = {},
  --       extensions = {}
  --     })
  --   end }, },

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
