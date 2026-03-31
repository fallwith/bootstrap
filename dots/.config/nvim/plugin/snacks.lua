require("snacks").setup({
  picker = {
    files = {
      exclude = {
        ".git",
        ".github",
        "public",
        "log",
      },
    },
    win = {
      input = {
        keys = {
          -- close the picker on ESC instead of going to normal mode
          ["<Esc>"] = { "close", mode = { "n", "i" } },
          -- The default C-Up and C-Down conflict with macOS
          ["<C-]>"] = { "history_forward", mode = { "i", "n" } },
          ["<C-[>"] = { "history_back", mode = { "i", "n" } },
        },
      },
    },
  },
})

vim.keymap.set("n", "<leader>f", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>g", function() Snacks.picker.grep() end, { desc = "Grep" })
vim.keymap.set({ "n", "x" }, "<leader>gs", function() Snacks.picker.grep_word() end, { desc = "Visual selection or word" })
vim.keymap.set("n", "<leader>b", function() Snacks.picker.buffers() end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Help Pages" })
vim.keymap.set("n", "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
vim.keymap.set("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>uC", function() Snacks.picker.colorschemes() end, { desc = "Colorschemes" })
