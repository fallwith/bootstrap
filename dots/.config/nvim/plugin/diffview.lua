-- view all git diffs in a single nvim session
--
-- do (Diff Obtain): Use the copy from the other file
-- dp (Diff Put): Use the copy from this file
-- ]c (jumpto-diffs): jump forwards to next change
-- [c (jumpto-diffs): jump backwards to previous change

vim.api.nvim_set_keymap("n", "<leader>d", ":lua " ..
  'local diffview = require("diffview.lib") ' ..
  "if next(diffview.views) == nil then " ..
    'vim.cmd("DiffviewOpen") ' ..
  "else " ..
    'vim.cmd("DiffviewClose") ' ..
  "end " ..
  "<CR>", { noremap = true, silent = true })
