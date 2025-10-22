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
      "febyeji/bluehour.nvim",
      "rmehri01/onenord.nvim",
      "sainnhe/edge",
      "LuRsT/austere.vim",
      "ribru17/bamboo.nvim",
      "samharju/serene.nvim",
      "EdenEast/nightfox.nvim",
      "vague2k/vague.nvim",
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
      "RostislavArts/naysayer.nvim",
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
        "bluehour",
        "onenord",
        "edge",
        "bamboo",
        "serene",
        "nightfox",
        "nordfox",
        "vague",
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
        "naysayer",
        "ymir",
        "juliana",
        "shizukana-dusk",
        "backpack",
        "void",
        "nkxxll/ghostty-default-style-dark.nvim",
        "nanode",
        "myrrh",
        "fourcolor",
        "folk-ushirogami",
        "folk-snawfus",
        "folk-abraxas",
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
