return {
  "nvim-lualine/lualine.nvim",
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  config = function()
    -- mock nvim_web_devicons until lualine supports mini.icons
    require("mini.icons").mock_nvim_web_devicons()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = "gruvbox-material",
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}
