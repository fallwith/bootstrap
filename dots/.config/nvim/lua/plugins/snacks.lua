return {
  "folke/snacks.nvim",
  opts = {
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
  },
  keys = {
    { "<leader>f", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    -- { "<leader>f", function() Snacks.picker.files() end, desc = "Find Files" },
    -- { "<leader>f", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    { "<leader>g", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>gs", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    { "<leader>b", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
  },
  lazy = false,
}
