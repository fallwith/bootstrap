local lint = require('lint')
lint.linters_by_ft = {
  ruby = {'rubocop'},
  rust = {'rust_lint'}
}
local lint_format = '%E%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
                 .. 'error:%.%\\{-} %m,%W%f:%l:%c: %\\d%#:%\\d%# %.%\\{-}'
                 .. 'warning:%.%\\{-} %m,%C%f:%l %m,%-G,%-G'
                 .. 'error: aborting %.%#,%-G'
                 .. 'error: Could not compile %.%#,%E'
                 .. 'error: %m,%Eerror[E%n]: %m,%-G'
                 .. 'warning: the option `Z` is unstable %.%#,%W'
                 .. 'warning: %m,%Inote: %m,%C %#--> %f:%l:%c'

-- rust-vim-lint binary is a shell script as follows:
--
-- #!/usr/bin/env sh
--
-- test "$1" || exit 1
--
-- d=$(dirname "$(realpath "$1")")
-- while test "$(echo "$d" | grep -o '/' | wc -l)" -ge 1
-- do
--     test -f "$d/Cargo.toml" && {
--         cd "$d" || exit 1
--         exec cargo check
--     }
--     d=$(echo "$d" | sed s/'\/[^\/]*$'//)
-- done
--
-- exec clippy-driver "$1"

lint.linters.rust_lint = {
    cmd = 'rust-vim-lint',
    stdin = false,
    append_fname = true,
    args = {},
    stream = 'both',
    ignore_exitcode = false,
    env = nil,
    parser = require('lint.parser').from_errorformat(lint_format)
}
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

