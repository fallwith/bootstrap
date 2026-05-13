-- these monochromatic ones are installed and available,
-- but not part of the rotation:
-- "monochrome", "e-ink", "zazen", "austere"

local schemes = {
  "catppuccin-macchiato",
  "mellow",
  "gruvbox-material",
  "everforest",
  "everforest", -- give this one more chances to be picked
  "everforest",
  "everforest",
  "everforest",
  "sonokai",
  "rose-pine-moon",
  "onenord",
  "edge",
  "bamboo",
  "serene",
  "nightfox",
  "nordfox",
  "kanagawa-wave",
  "kanagawa-wave",
  "kanagawa-wave",
  "melange",
  "nightfly",
  "darcula-dark",
  "onedark",
  "zzz",
  "stone-base",
  "stone-dark",
  "lytmode", -- favored
  "lytmode",
  "lytmode",
  "lytmode",
  "ymir",
  "juliana", -- favored
  "juliana",
  "juliana",
  "juliana",
  "shizukana-dusk",
  "backpack",
  "void",
  "ghostty-default-style-dark",
  "nanode",
  "myrrh",
  "fourcolor",
  "folk-ushirogami",
  "earthsong",
  "earthsong-mute",
  "stilla",
  "hubbamax",
  "eggfriedrice",
  "koda",
  "kaimandres",
  "aetheramethyst-eclipse",
  "moegi-dark",
  "moegi-space",
  "bebop",
  "noctis-sereno", -- non-sereno ones don't look right with highlighting + visual selection
  "gondolin",
  "tailwind-theme",
  "cursor-dark",
  "godot",
  "kukishinobu",
  "nekomi",
  "fieldlights",
  "Aquavium",
  "molokai-nvim",
  "one-dark-pro-max",
  "atomic",
  "atomic",
  "atomic",
  "atomic",
  "atomic-dark",
  "shale",
  "paragon",
  "nebula-drift-omega",
  "tomorrow-night-bright-r",
  "doric-water",
  "doric-plum",
  "doric-fire",
  "doric-valley",
  "doric-dark",
  "doric-obsidian",
  "doric-mermaid",
  "doric-pine",
  "doric-copper",
  "arcana",
  "eddy",
  "vague",
  "venice",
  "zenburned",
  "oc-2",
  "oc-2-noir",
  "bearded-arc",
  "lumon",
  "hearthlight",
  "hearthlight-ember",
  "hearthlight-parchment",
  "hearthlight-dusk",
  "hearthlight-cinder",
  "pastel",
  "pastelblack",
  "pastelcloud",
  "pastelcool",
  "pastelcream",
  "pasteldark",
  "pastelfog",
  "pastelforest",
  "pastelmint",
  "pastelpop",
  "pastelrose",
  "pastelwarm",
  "cobalt-kinetic",
  "olive-crt",
  "cynosure-dark",
  "sora",
  "tokyo-dark",
  "token",
  "north-sea",
  "mote",
  "muted_water",
  "muted_fire",
  "muted_earth",
  "muted_autumn",
  "muted_air",
  "muted",
  "ember",
  "ember-soft",
  "bonbon",
  "zorn",
  "zorn-umber",
  "zorn-plum",
  "zorn-dark",
  "zorn-blue",
  "carvion",
  "humdrum",
  "nimmy",
  "nimmy-hard",
  "neon-ghost",
  "kintsugi-flared",
  "kintsugi-dark",
  "thorn",
  "thorn-dark-warm",
  "thorn-dark-cold",
  "metsanpeitto", -- favored
  "metsanpeitto-tihea",
  "metsanpeitto-tihea",
  "metsanpeitto-tihea",
  "metsanpeitto-tihea",
  "metsanpeitto-syksy",
  "metsanpeitto-syksy",
  "metsanpeitto-syksy",
  "metsanpeitto-syksy",
  "metsanpeitto-sumu",
  "metsanpeitto-sumu",
  "metsanpeitto-sumu",
  "metsanpeitto-sumu",
  "nightSyscall",
  "cybersynth",
  "neonwave",
}
-- when the colorscheme changes, swap lualine to a matching theme if one
-- ships with the colorscheme (e.g. metsanpeitto, everforest, kanagawa).
-- try ev.match first (the requested name), then g:colors_name (what the
-- scheme set itself to -- e.g. kanagawa-wave -> kanagawa).
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function(ev)
    for _, name in ipairs({ ev.match, vim.g.colors_name }) do
      if name and pcall(require, 'lualine.themes.' .. name) then
        local config = require('lualine').get_config()
        config.options.theme = name
        require('lualine').setup(config)
        vim.g.lualine_theme = name
        return
      end
    end
  end,
})

math.randomseed(os.time())
vim.cmd.colorscheme(schemes[math.random(#schemes)])

-- use `:colorscheme` or `:echo g:colors_name` to get the current
-- color scheme
--
-- use these to set background colors. for transparency, use 'none'
--
-- highlight Normal guibg=none
-- highlight NonText guibg=none
-- highlight Normal ctermbg=none
-- highlight NonText ctermbg=none

--
-- greys for background usage
--
-- dark #282c34
-- charcoal #21252b
-- gunmetal #1c1f26
-- eclipse #1a1d23
-- pitch #181a20
-- obsidian	#14161c
