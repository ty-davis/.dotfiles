local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.enable_wayland = true
config.window_decorations = "NONE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.font_size = 18.0
config.hide_tab_bar_if_only_one_tab = true

return config
