-- remove the editor trimmings from terminal splits
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.spell = false
  end,
})

-- git commits
local gitCommitGroup = vim.api.nvim_create_augroup("gitcommit", { clear = true })
vim.api.nvim_create_autocmd("Filetype", {
  pattern = "gitcommit",
  command = "setlocal spell textwidth=72 colorcolumn=50,72",
  group = gitCommitGroup,
})
