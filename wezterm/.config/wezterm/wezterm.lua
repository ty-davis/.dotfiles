local wezterm = require('wezterm')
local act = wezterm.action
local state_manager = require('state_manager')
local project_commands = require('project_commands')

local config = wezterm.config_builder()

-- get the local config and load it if it's present
local state_file
local function load_local_config()
    local local_config_path = wezterm.config_dir .. '/local/init.lua'
    local local_result, err = loadfile(local_config_path)
    if local_result then
        local local_result_tab = local_result()
        state_file = local_result_tab.state_file
        return local_result_tab.local_config
    else
        wezterm.log_info("No local configuration was found, or there was an error loading it: " .. (err or "unknown error"))
        return {}
    end
end

-- colorscheme and font
config.command_palette_font_size = 12
config.window_frame = {
    font_size = 9,
}


-- window size/padding
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5,
}
config.initial_rows = 24
config.initial_cols = 100


-- custom commands for the command palette
local function toggle_background(win, pane)
    local state = state_manager.read_state(state_file)

    state.use_background_image = not state.use_background_image
    state_manager.write_state(state, state_file)
    win:perform_action(act.ReloadConfiguration, pane)
end

local function toggle_ligatures(win, pane)
    local state = state_manager.read_state(state_file)

    state.use_ligatures = not state.use_ligatures

    if state.use_ligatures then
        config.harfbuzz_features = { 'calt=0' }
    end
    state_manager.write_state(state, state_file)
    win:perform_action(act.ReloadConfiguration, pane)
end

local new_commands = {
    {
        brief = 'Rename this tab',
        icon = 'md_rename_box',

        action = act.PromptInputLine {
            description = 'Enter new name for tab',
            action = wezterm.action_callback(function(window, pane_2, line)
                if line then
                    window:active_tab():set_title(line)
                    -- window:toast_notification('wezterm', 'tab was renamed', nil, 4000)
                end
            end),
        }
    },
    {
        brief = 'Toggle background image',
        icon = 'md_image_area',

        action = wezterm.action_callback(toggle_background),
    },
    {
        brief = 'Toggle ligatures',
        icon = 'fa_font',
        action = wezterm.action_callback(toggle_ligatures),
    },
    table.unpack(project_commands.get_commands()),
}

wezterm.on('augment-command-palette', function(win, pane)
    return new_commands
end)

-- config.keys = {
--     {key = "H", mods="CTRL|"}
-- }

local launch_menu = {}

-- powershell if on windows
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.default_prog = {'powershell.exe'}
    table.insert(launch_menu, {
        label = 'Powershell',
        args = {'powershell.exe', '-NoLogo' },
    })
end

config.launch_menu = launch_menu


local local_config = load_local_config()
for k, v in pairs(local_config) do
    config[k] = v
end

if state_file then
    local this_state = state_manager.read_state(state_file)
    if this_state.use_ligatures then
        config.harfbuzz_features = { 'calt=0' }
    end
end

return config
