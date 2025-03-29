return {
  "stevearc/oil.nvim",
  opts = {
    view_options = {
      show_hidden = true,
    },
  },
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  keys = {
    { "-", mode = { "n" }, "<CMD>Oil<CR>", desc = "Launch Oil" },
  },
}
