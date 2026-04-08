-- disable built-in plugins we don't use
local disabled_builtins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "matchit",
  "netrw",
  "netrwFileHandlers",
  "netrwPlugin",
  "netrwSettings",
  "remote_plugins",
  "rrhelper",
  "spellfile_plugin",
  "tar",
  "tarPlugin",
  "tutor",
  "vimball",
  "vimballPlugin",
}
for _, plugin in ipairs(disabled_builtins) do
  vim.g["loaded_" .. plugin] = 1
end

-- run :TSUpdate when treesitter is installed or updated
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end
})

vim.pack.add({
  -- shared dependency
  "https://github.com/echasnovski/mini.icons",

  -- colorschemes
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
  "https://github.com/mellow-theme/mellow.nvim",
  "https://github.com/sainnhe/gruvbox-material",
  "https://github.com/sainnhe/everforest",
  "https://github.com/sainnhe/sonokai",
  "https://github.com/rose-pine/neovim",
  "https://github.com/rmehri01/onenord.nvim",
  "https://github.com/sainnhe/edge",
  "https://github.com/LuRsT/austere.vim",
  "https://github.com/ribru17/bamboo.nvim",
  "https://github.com/samharju/serene.nvim",
  "https://github.com/EdenEast/nightfox.nvim",
  "https://github.com/fxn/vim-monochrome",
  "https://github.com/alexxGmZ/e-ink.nvim",
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/savq/melange-nvim",
  "https://github.com/bluz71/vim-nightfly-colors",
  "https://github.com/xiantang/darcula-dark.nvim",
  "https://github.com/navarasu/onedark.nvim",
  "https://github.com/zaki/zazen",
  "https://github.com/r1cardohj/zzz.vim",
  "https://github.com/wesenseged/stone.nvim",
  "https://github.com/github-main-user/lytmode.nvim",
  "https://github.com/RonelXavier/ymir.nvim",
  "https://github.com/kaiuri/juliana.nvim",
  "https://github.com/avuenja/shizukana.nvim",
  "https://github.com/mitch1000/backpack.nvim",
  "https://github.com/vyrx-dev/void.nvim",
  "https://github.com/nkxxll/ghostty-default-style-dark.nvim",
  "https://github.com/KijitoraFinch/nanode.nvim",
  "https://github.com/utakotoba/myrrh.nvim",
  "https://github.com/zanshin/nvim-fourcolor-theme",
  { src = "https://github.com/folksoftware/nvim", name = "folk-nvim" },
  "https://github.com/guillermodotn/nvim-earthsong",
  "https://github.com/dlvandenberg/stilla.nvim",
  "https://github.com/alexpasmantier/hubbamax.nvim",
  "https://github.com/eggfriedrice24/eggfriedrice.nvim",
  "https://github.com/oskarnurm/koda.nvim",
  "https://github.com/MartelleV/kaimandres.nvim",
  "https://github.com/fallwith/AetherAmethyst.nvim",
  "https://github.com/maroozm/moegi-neovim",
  "https://github.com/ATTron/bebop.nvim",
  "https://github.com/Old-Farmer/noctis-nvim",
  "https://github.com/wunki/gondolin.nvim",
  "https://github.com/NisonChrist/tailwind-theme.nvim",
  "https://github.com/bergholmm/cursor-dark.nvim",
  "https://github.com/voylin/godot_color_theme",
  "https://github.com/aisk/kukishinobu.vim",
  "https://github.com/kotsuban/nekomi.nvim",
  "https://github.com/waytoopurple/fieldlights.nvim",
  "https://github.com/T-b-t-nchos/Aquavium.nvim",
  "https://github.com/jakubkarlicek/molokai-nvim",
  "https://github.com/Kopihue/one-dark-pro-max",
  "https://github.com/kurund/atomic.nvim",
  "https://github.com/smit4k/shale.nvim",
  "https://github.com/nnavales/paragon",
  "https://github.com/ikelaiah/nebula-drift-omega",
  "https://github.com/hopsk/tomorrow-night-bright-rstudio.nvim",
  "https://github.com/aymenhafeez/doric-themes.nvim",
  "https://github.com/bashful-strix/arcana",
  "https://github.com/m-mead/eddy.nvim",
  "https://github.com/vague-theme/vague.vim",
  "https://github.com/ilm-alan/venice.vim",
  "https://github.com/marcos-venicius/zenburned",
  "https://github.com/0xleodevv/oc-2.nvim",
  "https://github.com/kcayme/bearded-arc.nvim",
  "https://github.com/omacom-io/lumon.nvim",
  "https://github.com/dgrco/hearthlight.nvim",
  "https://github.com/ankushbhagats/pastel.nvim",
  "https://github.com/mohseenrm/brutus",
  "https://github.com/reobin/olive-crt.nvim",
  "https://github.com/gillisc/cynosure.nvim",
  "https://github.com/aejkatappaja/sora",
  "https://github.com/sudoscrawl/tokyo-dark.nvim",
  "https://github.com/thorstenrhau/token",
  "https://github.com/terkelg/north-sea.nvim",
  "https://github.com/davidklassen/mote",
  "https://github.com/pisgahk/muted.nvim",

  -- editing
  "https://github.com/folke/flash.nvim",
  "https://github.com/kylechui/nvim-surround",

  -- git
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/sindrets/diffview.nvim",

  -- linting
  "https://github.com/mfussenegger/nvim-lint",

  -- notes
  "https://github.com/serenevoid/kiwi.nvim",

  -- statusline
  "https://github.com/nvim-lualine/lualine.nvim",

  -- syntax
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/RRethy/nvim-treesitter-endwise",

  -- file browsing
  "https://github.com/stevearc/oil.nvim",

  -- picker
  "https://github.com/folke/snacks.nvim",

  -- testing
  "https://github.com/vim-test/vim-test",

  -- marks
  "https://github.com/chentoast/marks.nvim",
})

require("mini.icons").setup({})
