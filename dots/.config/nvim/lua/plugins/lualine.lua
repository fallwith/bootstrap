return {
  "nvim-lualine/lualine.nvim",
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  config = function()
    -- mock nvim_web_devicons until lualine supports mini.icons
    require("mini.icons").mock_nvim_web_devicons()

    local themes = {
      "dracula",
      "everforest",
      "gruvbox-material",
      "jellybeans",
      "material",
      "modus-vivendi",
      "moonfly",
      "nord",
      "OceanicNext",
      "onedark",
      "powerline",
      "seoul256",
      "tomorrow_night",
    }
    math.randomseed(os.time())
    local selected_theme = themes[math.random(#themes)]

    -- Store the selected theme globally for querying with :Luatheme
    vim.g.lualine_theme = selected_theme

    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = selected_theme,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "diff", "diagnostics" },
        lualine_c = {
          {
            "buffers",
            buffers_color = {
              active = { fg = '#ffffff' },
              inactive = { fg = '#808080' }
            },
            hide_filename_extension = true,
            icons_enabled = false,
            component_separators = { left = "", right = "" },
          }
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}
