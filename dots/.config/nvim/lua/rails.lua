-- Use :A to switch between app/ and spec/ content (ala vim.rails).
-- Adapted from garybernhardt's .vimrc:
--   https://github.com/garybernhardt/dotfiles/blob/e0786e861687af64b7ea3f1b9f2b66a8bfbfe6bf/.vimrc#L400-L428
function OpenTestAlternate()
  local alt_file = AlternateForCurrentFile()
  vim.cmd("e " .. alt_file)
end
function AlternateForCurrentFile()
  local file = vim.fn.expand("%")
  local in_spec = string.match(file, "^spec/") ~= nil
  local in_app = string.match(file, "^app/") ~= nil
  if in_spec then
    file = string.gsub(file, "_spec%.rb$", ".rb")
    file = string.gsub(file, "^spec/", "app/")
  else
    if in_app then
      file = string.gsub(file, "^app/", "")
    end
    file = string.gsub(file, "%.e?rb$", "_spec.rb")
    file = "spec/" .. file
  end
  return file
end
vim.api.nvim_create_user_command('A', OpenTestAlternate, {})
