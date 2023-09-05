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
  'tpope/vim-surround',

  -- add helpful closing structures (like 'end') for Ruby and others
  'tpope/vim-endwise',

  -- allow . to repeat plugin based operations
  'tpope/vim-repeat',

  -- simple file browsing
  'tpope/vim-vinegar',

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
  'sindrets/diffview.nvim',

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
  { 'rose-pine/neovim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('rose-pine')
    end }
})
