local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.default_prog = {"powershell.exe"}
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 14.0
config.leader = { key = "s", mods = "CTRL" }
config.tab_bar_at_bottom = true
-- config.color_scheme = 'Unsifted Wheat (terminal.sexy)'
-- config.color_scheme = 'Black Metal (Nile) (base16)'
config.color_scheme = 'Black Metal (base16)'

require("wez-tmux.plugin").apply_to_config(config, {})

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup({
  options = {
    icons_enabled = true,
    theme = config.color_scheme,
    tabs_enabled = true,
    theme_overrides = {},
    section_separators = '',
    component_separators = '',
    tab_separators = '',
  },
  sections = {
    tabline_a = { 'domain' },
    tabline_b = { '' },
    tabline_c = { '' },
    tab_active = { 'index', { 'process' } },
    tab_inactive = { 'index', { 'process' } },
    tabline_x = { ''},
    tabline_y = { '' },
    tabline_z = { 'datetime' },
  },
  extensions = {},
})

tabline.apply_to_config(config)
return config
