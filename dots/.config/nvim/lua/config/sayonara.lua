-- logic borrowed from mhinz/vim-sayonara and ported to Lua
-- I didn't need :Sayonara! (no need for the bang)
-- I didn't need to scan for other open instances of a buffer
-- I wanted to wire up :q and :wq to use it
local M = {}

function M.sayonara()
  local bufnr = vim.api.nvim_get_current_buf()

  local listed_buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #listed_buffers <= 1 then
    vim.cmd("quit")
  else
    vim.cmd("bdelete")
  end
end

function M.setup()
  vim.api.nvim_create_user_command("Sayonara", function() M.sayonara() end, {})

  vim.cmd [[
    cnoreabbrev <expr> q  getcmdtype() == ':' && getcmdline() == 'q'  ? 'Sayonara'       : 'q'
    cnoreabbrev <expr> wq getcmdtype() == ':' && getcmdline() == 'wq' ? 'w <bar> Sayonara' : 'wq'
  ]]
end

return M
