-- vimwiki lite
--
-- need to run `mkdir ~/.wiki && touch ~/.wiki/index.md`
--
-- leader+ww to launch
-- T to toggle [ ] to [x]
-- visual select (usually v+e) and hit Enter to create a link
-- ctrl+o to navigate back
return {
  "serenevoid/kiwi.nvim",
  opts = { { name = "wiki", path = vim.fn.expand("~/.wiki") } },
  lazy = true,
  keys = {
    { "<leader>w", mode = { "n" }, function() require("kiwi").open_wiki_index() end, desc = "Open main wiki index" },
    { "T", function() require("kiwi").todo.toggle() end, desc = "Toggle checkboxes" },
  },
}
