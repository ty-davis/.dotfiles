-- local config

local wezterm = require('wezterm')
local state_manager = require('state_manager')
local config = wezterm.config_builder()



config.font = wezterm.font_with_fallback({"CaskaydiaCove Nerd Font Mono"})
config.font_size = 11.5

config.color_scheme = 'Vs Code Dark+ (Gogh)'

local state_file = "C:/Users/tydav/.config/wezterm/local/state.json"

local state = state_manager.read_state(state_file)
if state.use_background_image then
    config.background = {
        {
            source = { File = 'C:/Users/tydav/.config/wezterm/imgs/cycle/' .. math.random(7) .. '.png' },
            width = 'Cover',
            height = 'Cover',
            horizontal_align = 'Center',
            vertical_align = 'Middle',
            hsb = {
                brightness = 0.04,
                hue = 1.0,
                saturation = 0.8,
            },
        },
    }
    config.text_background_opacity = 0.5
end

if state.use_ligatures then
    config.harfbuzz_features = { 'calt=0' }
end

config.command_palette_font_size = 10.5

config.window_frame = {
    font = wezterm.font_with_fallback({"CaskaydiaCove Nerd Font Mono"}),
    font_size = 9,
}

-- config.default_domain = 'WSL:Ubuntu'

local result = {
    local_config = config,
    state_file = state_file
}

return result
