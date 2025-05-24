return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    dependencies = {
      "mellow-theme/mellow.nvim",
      "sainnhe/gruvbox-material",
      "sainnhe/everforest",
      "sainnhe/sonokai",
      "folke/tokyonight.nvim",
      "rose-pine/neovim",
      "febyeji/bluehour.nvim",
      "rmehri01/onenord.nvim",
      "sainnhe/edge",
      "LuRsT/austere.vim",
      "ribru17/bamboo.nvim",
      "ellisonleao/gruvbox.nvim",
      "samharju/serene.nvim",
      "pauchiner/pastelnight.nvim",
      "dasupradyumna/midnight.nvim",
      "EdenEast/nightfox.nvim",
      "vague2k/vague.nvim",
      "fxn/vim-monochrome",
      "kamwitsta/vinyl.nvim",
      "alexxGmZ/e-ink.nvim",
      "rebelot/kanagawa.nvim",
      "savq/melange-nvim",
      "bluz71/vim-nightfly-colors",
      "xiantang/darcula-dark.nvim",
      "navarasu/onedark.nvim",
      "thesimonho/kanagawa-paper.nvim",
      "zaki/zazen",
      "r1cardohj/zzz.vim",
    },
    lazy = false,
    priority = 1000,
    config = function()
      local schemes = {
        "catppuccin-macchiato",
        "mellow",
        "gruvbox-material",
        "everforest",
        "sonokai",
        "tokyonight-moon",
        "rose-pine-moon",
        "bluehour",
        "onenord",
        "edge",
        "austere",
        "bamboo",
        "gruvbox",
        "serene",
        "pastelnight",
        "midnight",
        "duskfox",
        "nightfox",
        "nordfox",
        "vague",
        "monochrome",
        "vinyl",
        "e-ink",
        "kanagawa-wave",
        "melange",
        "nightfly",
        "darcula-dark",
        "onedark",
        "kanagawa-paper",
        "kanagawa-paper-canvas",
        "zazen",
        "zzz",
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
