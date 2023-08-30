local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

return require('packer').startup(function(use)
  -- have Packer manage itself
  use 'wbthomason/packer.nvim'

  -- comment out (and in) code
  use 'tpope/vim-commentary'

  -- add, remove, swap surroundings like quotes or braces
  use 'tpope/vim-surround'

  -- add helpful closing structures (like 'end') for Ruby and others
  use 'tpope/vim-endwise'

  -- allow . to repeat plugin based operations
  use 'tpope/vim-repeat'

  -- simple file browsing
  use 'tpope/vim-vinegar'

  -- code linting
  use 'mfussenegger/nvim-lint'

  -- fuzzy finding
  use { 'nvim-telescope/telescope.nvim', requires = { { 'nvim-lua/popup.nvim' },
                                                      { 'nvim-lua/plenary.nvim' },
                                                      { 'nvim-treesitter/nvim-treesitter' } } }

  -- view all git diffs in a single nvim session
  use { 'sindrets/diffview.nvim' }

  -- colorschemes
  -- use 'zaki/zazen'
  -- use 'fxn/vim-monochrome'
  -- use 'arcticicestudio/nord-vim'
  -- use 'nanotech/jellybeans.vim'
  -- use 'cocopon/iceberg.vim'
  -- use 'ldelossa/vimdark'
  -- use { 'Lokaltog/vim-distinguished', branch = 'develop' }
  use 'fallwith/seabird'
  -- use 'jaredgorski/fogbell.vim'
  -- use 'logico/typewriter-vim'
  -- use 'LuRsT/austere.vim'
  -- use 'sainnhe/edge'
  -- use 'sainnhe/sonokai'
  -- use 'Everblush/everblush.nvim'
  -- use 'folke/tokyonight.nvim'
  -- use 'rmehri01/onenord.nvim'
  -- use 'savq/melange'
  -- use 'ellisonleao/gruvbox.nvim'
  -- use 'lunarvim/darkplus.nvim'
  use 'rose-pine/neovim'

  if packer_bootstrap then
    require('packer').sync()
  end
end)
