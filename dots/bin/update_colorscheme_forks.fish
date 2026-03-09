#!/usr/bin/env fish

set repos \
  mellow-theme/mellow.nvim \
  sainnhe/gruvbox-material \
  sainnhe/everforest \
  sainnhe/sonokai \
  rose-pine/neovim \
  rmehri01/onenord.nvim \
  sainnhe/edge \
  LuRsT/austere.vim \
  ribru17/bamboo.nvim \
  samharju/serene.nvim \
  EdenEast/nightfox.nvim \
  fxn/vim-monochrome \
  alexxGmZ/e-ink.nvim \
  rebelot/kanagawa.nvim \
  savq/melange-nvim \
  bluz71/vim-nightfly-colors \
  xiantang/darcula-dark.nvim \
  navarasu/onedark.nvim \
  zaki/zazen \
  r1cardohj/zzz.vim \
  wesenseged/stone.nvim \
  github-main-user/lytmode.nvim \
  RonelXavier/ymir.nvim \
  kaiuri/juliana.nvim \
  avuenja/shizukana.nvim \
  mitch1000/backpack.nvim \
  vyrx-dev/void.nvim \
  nkxxll/ghostty-default-style-dark.nvim \
  KijitoraFinch/nanode.nvim \
  utakotoba/myrrh.nvim \
  zanshin/nvim-fourcolor-theme \
  folksoftware/nvim \
  guillermodotn/nvim-earthsong \
  dlvandenberg/stilla.nvim \
  alexpasmantier/hubbamax.nvim \
  eggfriedrice24/eggfriedrice.nvim \
  oskarnurm/koda.nvim \
  MartelleV/kaimandres.nvim \
  maroozm/moegi-neovim \
  ATTron/bebop.nvim \
  Old-Farmer/noctis-nvim \
  wunki/gondolin.nvim \
  NisonChrist/tailwind-theme.nvim \
  bergholmm/cursor-dark.nvim \
  voylin/godot_color_theme \
  aisk/kukishinobu.vim \
  kotsuban/nekomi.nvim \
  waytoopurple/fieldlights.nvim \
  T-b-t-nchos/Aquavium.nvim \
  jakubkarlicek/molokai-nvim \
  Kopihue/one-dark-pro-max \
  kurund/atomic.nvim \
  smit4k/shale.nvim \
  nnavales/paragon \
  ikelaiah/nebula-drift-omega \
  hopsk/tomorrow-night-bright-rstudio.nvim \
  aymenhafeez/doric-themes.nvim \
  bashful-strix/arcana \
  m-mead/eddy.nvim \
  vague-theme/vague.vim \
  ilm-alan/venice.vim

for repo in $repos
  set -l name (basename $repo)
  set -l fork fallwith/$name

  echo "=== $repo ==="
  gh repo fork $repo --clone=false --remote=false 2>&1
  gh repo sync $fork 2>&1
  echo ""
end
