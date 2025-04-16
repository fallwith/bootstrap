return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    dependencies = {
      "sainnhe/gruvbox-material",
      "sainnhe/everforest",
      "folke/tokyonight.nvim",
      "rebelot/kanagawa.nvim",
      "EdenEast/nightfox.nvim",
      "rose-pine/neovim",
      "xiantang/darcula-dark.nvim",
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
      }
      math.randomseed(os.time())
      vim.cmd.colorscheme(schemes[math.random(#schemes)])
    end,
  },
}

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
