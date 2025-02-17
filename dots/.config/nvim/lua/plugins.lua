local lazypath = vim.fn.stdpath('data')..'/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({'git',
                 'clone',
                 -- '--depth',
                 -- '1',
                 '--filter=blob:none',
                 'https://github.com/folke/lazy.nvim.git',
                 '--branch=stable',
                 lazypath})
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- comment out (and in) code
  'tpope/vim-commentary',

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
  { "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end },

  -- add helpful closing structures (like 'end') for Ruby and others
  'tpope/vim-endwise',

  -- allow . to repeat plugin based operations
  'tpope/vim-repeat',

  -- simple file browsing
  'tpope/vim-vinegar',

  -- programming languages
  'rust-lang/rust.vim',

  -- code linting
  { 'mfussenegger/nvim-lint',
    config = function()
      require 'linting'
    end },

  -- fuzzy finding
  { 'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/popup.nvim',
                     'nvim-lua/plenary.nvim',
                     'nvim-treesitter/nvim-treesitter' } },

  -- view all git diffs in a single nvim session
  { 'sindrets/diffview.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' } },

  { "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end },

  -- colorschemes
  -- 'zaki/zazen'
  -- 'fxn/vim-monochrome'
  -- 'arcticicestudio/nord-vim'
  -- 'nanotech/jellybeans.vim'
  -- 'cocopon/iceberg.vim'
  -- 'ldelossa/vimdark'
  -- { 'Lokaltog/vim-distinguished', branch = 'develop' }
  -- 'fallwith/seabird'
  -- 'jaredgorski/fogbell.vim'
  -- 'logico/typewriter-vim'
  -- 'LuRsT/austere.vim'
  -- 'sainnhe/edge'
  -- 'sainnhe/sonokai'
  -- 'Everblush/everblush.nvim'
  -- 'folke/tokyonight.nvim'
  -- 'rmehri01/onenord.nvim'
  -- 'savq/melange'
  -- 'ellisonleao/gruvbox.nvim'
  -- 'lunarvim/darkplus.nvim'
  -- 'rose-pine/neovim'
  { 'chriskempson/base16-vim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.base16colorspace = 256
      vim.o.background = 'dark'
      vim.cmd.colorscheme('base16-tomorrow-night')
      -- vim.cmd [[
      --   highlight Normal guibg=none
      --   highlight NonText guibg=none
      --   highlight Normal ctermbg=none
      --   highlight NonText ctermbg=none
      -- ]]
    end }
})
