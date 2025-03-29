-- code linting

return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      lua = { "luacheck" },
      ruby = { "rubocop" },
    }

    vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
      callback = function() require("lint").try_lint() end
    })
  end,
}
