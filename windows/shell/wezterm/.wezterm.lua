local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.default_prog = {"powershell.exe"}
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.window_close_confirmation = 'NeverPrompt'

config.default_cursor_style = 'BlinkingBar'
config.cursor_thickness = 1.5
config.animation_fps = 240
config.max_fps = 240
config.cursor_blink_rate = 1300

config.font = wezterm.font("Iosevka Nerd Font")
config.font_size = 14.0

config.wsl_domains = {
  {
    name = 'WSL:archlinux',
    distribution = 'Arch',
    username = 'drama',
    default_cwd = '~',
    default_prog = {'zsh'},
  },
}

config.leader = { key = "a", mods = "CTRL" }
config.tab_bar_at_bottom = true
config.color_scheme = 'Black Metal (Gorgoroth) (base16)'

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
    tabline_a = { '' },
    tabline_b = { '' },
    tabline_c = { '' },
    tab_active = { 'process' },
    tab_inactive = {  'cwd' },
    tabline_x = { ''},
    tabline_y = { '' },
    tabline_z = { '' },
  },
  extensions = {},
})
tabline.apply_to_config(config)

return config
