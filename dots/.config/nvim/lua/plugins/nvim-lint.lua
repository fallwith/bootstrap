-- code linting

return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")

    lint.linters.rubocop.cmd = "bundle"
    lint.linters.rubocop.args = {
      "exec",
      "rubocop",
      "--format",
      "json",
      "--force-exclusion",
      "--server",
      "--stdin",
      function() return vim.api.nvim_buf_get_name(0) end
    }

    lint.linters_by_ft = {
      lua = { "luacheck" },
      ruby = { "rubocop" },
    }

    vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
      callback = function() require("lint").try_lint() end
    })
  end,
}
