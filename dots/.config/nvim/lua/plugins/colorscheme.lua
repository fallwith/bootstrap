return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    dependencies = {
      "mellow-theme/mellow.nvim",
      "sainnhe/gruvbox-material",
      "sainnhe/everforest",
      "sainnhe/sonokai",
      "rose-pine/neovim",
      "rmehri01/onenord.nvim",
      "sainnhe/edge",
      "LuRsT/austere.vim",
      "ribru17/bamboo.nvim",
      "samharju/serene.nvim",
      "EdenEast/nightfox.nvim",
      "fxn/vim-monochrome",
      "alexxGmZ/e-ink.nvim",
      "rebelot/kanagawa.nvim",
      "savq/melange-nvim",
      "bluz71/vim-nightfly-colors",
      "xiantang/darcula-dark.nvim",
      "navarasu/onedark.nvim",
      "zaki/zazen",
      "r1cardohj/zzz.vim",
      "wesenseged/stone.nvim",
      "github-main-user/lytmode.nvim",
      "RonelXavier/ymir.nvim",
      "kaiuri/juliana.nvim",
      "avuenja/shizukana.nvim",
      "mitch1000/backpack.nvim",
      "vyrx-dev/void.nvim",
      "nkxxll/ghostty-default-style-dark.nvim",
      "KijitoraFinch/nanode.nvim",
      "utakotoba/myrrh.nvim",
      "zanshin/nvim-fourcolor-theme",
      "folksoftware/nvim",
      "guillermodotn/nvim-earthsong",
      "dlvandenberg/stilla.nvim",
      "alexpasmantier/hubbamax.nvim",
      "eggfriedrice24/eggfriedrice.nvim",
      "oskarnurm/chiefdog.nvim",
      "MartelleV/kaimandres.nvim",
      "aethersyscall/AetherAmethyst.nvim",
      "maroozm/moegi-neovim",
      "ATTron/bebop.nvim",
      "Old-Farmer/noctis-nvim",
      "wunki/gondolin.nvim",
      "NisonChrist/tailwind-theme.nvim",
    },
    lazy = false,
    priority = 1000,
    config = function()
      -- these monochromatic ones are installed and available, but not part of the rotation
      -- "monochrome",
      -- "e-ink",
      -- "zazen",
      -- "austere",

      local schemes = {
        "catppuccin-macchiato",
        "mellow",
        "gruvbox-material",
        "everforest",
        "everforest", -- give this one more chances to be picked
        "everforest",
        "everforest",
        "everforest",
        "sonokai",
        "rose-pine-moon",
        "onenord",
        "edge",
        "bamboo",
        "serene",
        "nightfox",
        "nordfox",
        "kanagawa-wave",
        "melange",
        "nightfly",
        "darcula-dark",
        "onedark",
        "zzz",
        "stone-base",
        "stone-dark",
        "lytmode", -- favored
        "lytmode",
        "lytmode",
        "lytmode",
        "ymir",
        "juliana",
        "shizukana-dusk",
        "backpack",
        "void",
        "ghostty-default-style-dark",
        "nanode",
        "myrrh",
        "fourcolor",
        "folk-ushirogami",
        "earthsong",
        "earthsong-mute",
        "stilla",
        "hubbamax",
        "eggfriedrice",
        "chiefdog",
        "kaimandres",
        "aetheramethyst-eclipse",
        "moegi-dark",
        "moegi-space",
        "bebop",

        "noctis-azureus",
        "noctis-bordo",
        "noctis-minimus",
        "noctis-obscuro",
        "noctis-sereno",
        "noctis-uva",
        "noctis-viola",
        "gondolin",
        "tailwind-theme",
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
