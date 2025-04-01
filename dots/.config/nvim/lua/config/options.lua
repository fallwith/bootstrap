vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- visually style columns at the given position(s)
vim.opt.colorcolumn = "80,120"

-- autocompletion options
--   menuone: use the menu even if there's only one available option
--   noselect: always force a manual selection instead of providing a default one
vim.opt.completeopt = "menuone,noinsert,noselect"

-- expand tabs to spaces
vim.opt.expandtab = true

-- highlight search matches
vim.opt.hlsearch = true

-- case insensitive searching
vim.opt.ignorecase = true

-- show the effects (or results) of a command (or a search) incrementally
vim.opt.inccommand = "nosplit"

-- when searching, incrementally show the current results as the search pattern
--   continue to be built
vim.opt.incsearch = true

-- always show the status line of the last window
vim.opt.laststatus = 2

-- display line numbers
vim.opt.number = true

-- pad the given number of lines above and below the cursor for context
vim.opt.scrolloff = 5

-- round indentation to a multiple of 'shiftwidth'
vim.opt.shiftround = true

-- how many spaces to indent/outdent
vim.opt.shiftwidth = 2

-- trigger case sensistivity when two differently case characters are present
vim.opt.smartcase = true

-- tabs are 2 spaces
vim.opt.tabstop = 2

-- enable gui style colors in the terminal (true 24 bit color support)
vim.opt.termguicolors = true

-- time to wait after ESC
-- vim.opt.timeoutlen = 250

-- automatically update the window's title to show the current filename
vim.opt.title = true

 -- file based persistent undo
vim.opt.undofile = true
vim.bo.undofile = true

-- when tab completing commands, show available matches in a menu
vim.opt.wildmenu = true

-- diagnostics config for linters and LSPs
vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
  },
})
