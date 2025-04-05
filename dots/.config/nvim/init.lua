require "config.options"
require "config.lazy"
require "config.mappings"
require "config.rails"
require "config.autocmd"
if vim.g.neovide then
  require "config.neovide"
end
