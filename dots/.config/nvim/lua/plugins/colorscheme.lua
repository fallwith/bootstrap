return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
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
