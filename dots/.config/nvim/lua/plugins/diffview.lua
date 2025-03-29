-- view all git diffs in a single nvim session

return {
  "sindrets/diffview.nvim",
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  config = function()
  -- vim.api.nvim_set_keymap('n', '<leader>d', ':DiffviewOpen<CR>', {noremap = true})
  -- https://www.reddit.com/r/neovim/comments/1j9fy2w/comment/mhd8dt3/
  vim.api.nvim_set_keymap("n", "<leader>d", ":lua " ..
    'local diffview = require("diffview.lib") ' ..
    "if next(diffview.views) == nil then " ..
      'vim.cmd("DiffviewOpen") ' ..
    "else " ..
      'vim.cmd("DiffviewClose") ' ..
    "end " ..
    "<CR>", { noremap = true, silent = true })
  end
}
