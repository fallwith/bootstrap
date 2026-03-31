-- tree sitting (https://elevenpond.bandcamp.com/track/watching-trees)

return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    -- treesitter based port of tpope's endwise
    "RRethy/nvim-treesitter-endwise"
  },
  build = ':TSUpdate',
  config = function()
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
  end,
}
