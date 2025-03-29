-- tree sitting (https://elevenpond.bandcamp.com/track/watching-trees)

return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    -- context for what structure (method, etc.) the current line is in
    "nvim-treesitter/nvim-treesitter-context",
    -- treesitter based port of tpope's endwise
    "RRethy/nvim-treesitter-endwise"
  },
  run = ':TSUpdate',
  config = function()
    require("nvim-treesitter.configs").setup {
      ensure_installed = { "bash",
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
                           "yaml" },
      highlight = {
        enable = true,
      },
    }
  end,
}
