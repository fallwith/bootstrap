return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    dependencies = {
      "sainnhe/gruvbox-material",
      "sainnhe/everforest",
      "sainnhe/sonokai",
      "folke/tokyonight.nvim",
      "rebelot/kanagawa.nvim",
      "EdenEast/nightfox.nvim",
      "rose-pine/neovim",
      "xiantang/darcula-dark.nvim",
      "comfysage/cuddlefish.nvim",
      "everviolet/nvim",
      "vague2k/vague.nvim",
      "bluz71/vim-moonfly-colors",
      "navarasu/onedark.nvim",
      "zaki/zazen",
      "fxn/vim-monochrome",
      "arcticicestudio/nord-vim",
      "nanotech/jellybeans.vim",
      "cocopon/iceberg.vim",
      { "Lokaltog/vim-distinguished", branch = "develop" },
      "LuRsT/austere.vim",
      "sainnhe/edge",
      "rmehri01/onenord.nvim",
      "ellisonleao/gruvbox.nvim",
      "bluz71/vim-nightfly-colors",
      "dasupradyumna/midnight.nvim",
      "ribru17/bamboo.nvim",
      "mellow-theme/mellow.nvim",
      "projekt0n/caret.nvim",
      "savq/melange-nvim",
      "samharju/serene.nvim",
      "febyeji/bluehour.nvim",
      "alexxGmZ/e-ink.nvim",
      "pauchiner/pastelnight.nvim",
      "HoNamDuong/hybrid.nvim",
      "thesimonho/kanagawa-paper.nvim",
      "wesleimp/min-theme.nvim",
      "webhooked/kanso.nvim",
      "Skardyy/makurai-nvim",
      "kamwitsta/vinyl.nvim",
    },
    lazy = false,
    priority = 1000,
    config = function()
      local schemes = {
        "catppuccin-macchiato",
        "everforest",
        "gruvbox-material",
        "tokyonight-moon",
        "kanagawa-wave",
        "nightfox",
        "nordfox",
        "duskfox",
        "darcula-dark",
        "rose-pine-moon",
        "cuddlefish",
        "evergarden",
        "vague",
        "moonfly",
        "sonokai",
        "onedark",
        "zazen",
        "monochrome",
        "nord",
        "jellybeans",
        "distinguished",
        "iceberg",
        "austere",
        "edge",
        "onenord",
        "gruvbox",
        "nightfly",
        "midnight",
        "bamboo",
        "mellow",
        "caret",
        "melange",
        "serene",
        "bluehour",
        "e-ink",
        "pastelnight",
        "hybrid",
        "kanagawa-paper",
        "min-dark",
        "kanso-ink",
        "kanso-pearl",
        "kanso-zen",
        "makurai_healer",
        "makurai_mage",
        "makurai_rogue",
        "vinyl",
      }
      math.randomseed(os.time())
      vim.cmd.colorscheme(schemes[math.random(#schemes)])
    end,
  },
}

-- use `:colorscheme` or `:echo g:colors_name` to get the current color scheme
--
-- use these to set background colors. for transparency, use 'none'
--
-- highlight Normal guibg=none
-- highlight NonText guibg=none
-- highlight Normal ctermbg=none
-- highlight NonText ctermbg=none

--
-- greys for background usage
--
-- dark #282c34
-- charcoal #21252b
-- gunmetal #1c1f26
-- eclipse #1a1d23
-- pitch #181a20
-- obsidian	#14161c
