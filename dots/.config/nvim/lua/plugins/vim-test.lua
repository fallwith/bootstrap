-- run unit tests (nearest, all in file, all in project)

return {
  "vim-test/vim-test",
  -- vim-test requires a config block
  config = function()
    vim.api.nvim_create_user_command("TN", "TestNearest", {})
    vim.api.nvim_create_user_command("TF", "TestFile", {})
  end,
}
