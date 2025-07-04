require "config.options"
require "config.lazy"
require "config.mappings"
require "config.rails"
require "config.autocmd"
require("config.sayonara").setup()
if vim.g.neovide then
  require "config.neovide"
end
