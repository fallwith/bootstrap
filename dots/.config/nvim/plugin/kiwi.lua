-- vimwiki lite
--
-- need to run `mkdir ~/.wiki && touch ~/.wiki/index.md`
--
-- leader+w to launch
-- T to toggle [ ] to [x]
-- visual select (usually v+e) and hit Enter to create a link
-- ctrl+o to navigate back

require("kiwi").setup({ { name = "wiki", path = vim.fn.expand("~/.wiki") } })

vim.keymap.set("n", "<leader>w", function()
  require("kiwi").open_wiki_index()
end, { desc = "Open main wiki index" })

vim.keymap.set("n", "T", function()
  require("kiwi").todo.toggle()
end, { desc = "Toggle checkboxes" })
