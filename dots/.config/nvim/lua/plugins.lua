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

  -- code linting / formating
  use 'jose-elias-alvarez/null-ls.nvim'

  -- configuration for neovim's built-in lsp
  use 'neovim/nvim-lspconfig'

  -- fuzzy finding
  use { 'nvim-telescope/telescope.nvim', requires = { { 'nvim-lua/popup.nvim' },
                                                      { 'nvim-lua/plenary.nvim' },
                                                      { 'nvim-treesitter/nvim-treesitter' } } }

  -- autocompletion / snippets
  use { 'hrsh7th/nvim-cmp',
        requires = { { 'hrsh7th/vim-vsnip' },
                     { 'hrsh7th/cmp-vsnip', after = 'nvim-cmp' },
                     { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-cmp' },
                     { 'hrsh7th/cmp-nvim-lua', after = 'nvim-cmp' },
                     { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
                     { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
                     { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' } } }

  -- colorschemes
  use 'zaki/zazen'
  use 'fxn/vim-monochrome'
  use 'arcticicestudio/nord-vim'
  use 'morhetz/gruvbox'
  use 'sainnhe/gruvbox-material'
  use 'nanotech/jellybeans.vim'
  use 'cocopon/iceberg.vim'
  use 'ldelossa/vimdark'
  use { 'Lokaltog/vim-distinguished', branch = 'develop' }
  use 'nightsense/seabird'
  use 'jaredgorski/fogbell.vim'
  use 'logico/typewriter-vim'
  use 'LuRsT/austere.vim'

  if packer_bootstrap then
    require('packer').sync()
  end
end)
