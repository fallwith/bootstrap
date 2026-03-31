-- run unit tests (nearest, all in file, all in project)

vim.api.nvim_create_user_command("TN", "TestNearest", {})
vim.api.nvim_create_user_command("TF", "TestFile", {})
