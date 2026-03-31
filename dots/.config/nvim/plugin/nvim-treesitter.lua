-- tree sitting (https://elevenpond.bandcamp.com/track/watching-trees)

require("nvim-treesitter").setup()
require("nvim-treesitter").install({
  "bash",
  "diff",
  "editorconfig",
  "go",
  "javascript",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "ruby",
  "rust",
  "typescript",
  "yaml",
})
