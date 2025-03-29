-- display keybindings info and interactively guide the user to the right
-- binding. Config taken from LazyVim https://www.lazyvim.org/plugins/treesitter

return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      { "<BS>", desc = "Decrement Selection", mode = "x" },
      { "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },
    },
  },
}
