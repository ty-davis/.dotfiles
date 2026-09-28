local wezterm = require('wezterm')
local state_manager = require('state_manager')

local local_overrides = {}
local loaded_settings = nil
local loaded_state_file = nil
local has_legacy_local_config = false
local background_cycle = {
    images = nil,
    next_index = 1,
    image_dir = nil,
    last_image = nil,
}

local DEFAULT_STATE_FILE = 'local/state.json'
local DEFAULT_BACKGROUND_IMAGE_DIR = 'imgs/cycle'
local DEFAULT_BACKGROUND_HSB = {
    brightness = 0.04,
    hue = 1.0,
    saturation = 0.8,
}

local SUPPORTED_IMAGE_EXTENSIONS = {
    jpeg = true,
    jpg = true,
    png = true,
    webp = true,
}

local function seed_random()
    math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    math.random()
    math.random()
    math.random()
end

seed_random()

local function is_absolute_path(path)
    return path:sub(1, 1) == '/' or path:match('^%a:[/\\]')
end

local function resolve_path(path)
    if not path or path == '' then
        return nil
    end

    if is_absolute_path(path) then
        return path
    end

    return wezterm.config_dir .. '/' .. path
end

local function load_settings(settings_path)
    local chunk, err = loadfile(settings_path)
    if not chunk then
        wezterm.log_info('No local configuration was found, or there was an error loading it: ' .. (err or 'unknown error'))
        return {}
    end

    local ok, settings_or_err = pcall(chunk)
    if not ok then
        wezterm.log_error('Error while evaluating local configuration: ' .. tostring(settings_or_err))
        return {}
    end

    if type(settings_or_err) ~= 'table' then
        wezterm.log_error('Local configuration must return a table')
        return {}
    end

    return settings_or_err
end

local function build_font(font)
    if not font then
        return nil
    end

    if type(font) == 'string' then
        return wezterm.font_with_fallback({ font })
    end

    return wezterm.font_with_fallback(font)
end

local function is_supported_image(path)
    local extension = path:match('%.([^.]+)$')
    return extension and SUPPORTED_IMAGE_EXTENSIONS[extension:lower()] or false
end

local function list_background_images(image_dir)
    local ok, entries_or_err = pcall(wezterm.read_dir, image_dir)
    if not ok then
        wezterm.log_error('Could not read background image directory ' .. image_dir .. ': ' .. tostring(entries_or_err))
        return {}
    end

    local images = {}
    for _, entry in ipairs(entries_or_err) do
        if is_supported_image(entry) then
            table.insert(images, entry)
        end
    end
    table.sort(images)

    return images
end

local function shuffle_images(images)
    for index = #images, 2, -1 do
        local swap_index = math.random(index)
        images[index], images[swap_index] = images[swap_index], images[index]
    end
end

local function reset_background_cycle(image_dir, images)
    background_cycle.images = images
    background_cycle.next_index = 1
    background_cycle.image_dir = image_dir

    shuffle_images(background_cycle.images)
    if #background_cycle.images > 1 and background_cycle.images[1] == background_cycle.last_image then
        background_cycle.images[1], background_cycle.images[2] = background_cycle.images[2], background_cycle.images[1]
    end
end

local function choose_background_image(settings)
    local image_dir = resolve_path(settings.background_image_dir or DEFAULT_BACKGROUND_IMAGE_DIR)
    local needs_reload = background_cycle.images == nil or background_cycle.image_dir ~= image_dir
    if needs_reload then
        reset_background_cycle(image_dir, list_background_images(image_dir))
    end

    if not background_cycle.images or #background_cycle.images == 0 then
        return nil
    end

    if background_cycle.next_index > #background_cycle.images then
        reset_background_cycle(image_dir, list_background_images(image_dir))
        if not background_cycle.images or #background_cycle.images == 0 then
            return nil
        end
    end

    local next_image = background_cycle.images[background_cycle.next_index]
    background_cycle.next_index = background_cycle.next_index + 1
    background_cycle.last_image = next_image

    return next_image
end

local function build_background(image_path, settings)
    return {
        {
            source = { File = image_path },
            width = 'Cover',
            height = 'Cover',
            horizontal_align = 'Center',
            vertical_align = 'Middle',
            hsb = settings.background_hsb or DEFAULT_BACKGROUND_HSB,
        },
    }
end

local function extract_background_image(overrides)
    if not overrides or not overrides.background then
        return nil
    end

    local first_layer = overrides.background[1]
    if not first_layer or not first_layer.source then
        return nil
    end

    return first_layer.source.File
end

local function background_matches(overrides, desired_background, desired_opacity)
    local current_background = overrides.background
    if not current_background or not current_background[1] then
        return false
    end

    local current_layer = current_background[1]
    local desired_layer = desired_background[1]
    local current_hsb = current_layer.hsb or {}
    local desired_hsb = desired_layer.hsb or {}

    return current_layer.source
        and current_layer.source.File == desired_layer.source.File
        and current_layer.width == desired_layer.width
        and current_layer.height == desired_layer.height
        and current_layer.horizontal_align == desired_layer.horizontal_align
        and current_layer.vertical_align == desired_layer.vertical_align
        and current_hsb.brightness == desired_hsb.brightness
        and current_hsb.hue == desired_hsb.hue
        and current_hsb.saturation == desired_hsb.saturation
        and overrides.text_background_opacity == desired_opacity
end

local function apply_background(window, settings, state)
    local overrides = window:get_config_overrides() or {}

    if not state.use_background_image then
        if overrides.background == nil and overrides.text_background_opacity == nil then
            return
        end

        overrides.background = nil
        overrides.text_background_opacity = nil
        window:set_config_overrides(overrides)
        return
    end

    local image_path = extract_background_image(overrides) or choose_background_image(settings)
    if not image_path then
        local image_dir = resolve_path(settings.background_image_dir or DEFAULT_BACKGROUND_IMAGE_DIR)
        wezterm.log_error('No background images found in ' .. image_dir)
        return
    end

    local desired_opacity = settings.text_background_opacity or 0.5
    local desired_background = build_background(image_path, settings)
    if background_matches(overrides, desired_background, desired_opacity) then
        return
    end

    overrides.background = desired_background
    overrides.text_background_opacity = desired_opacity
    window:set_config_overrides(overrides)
end

local function apply_personal_settings(config, settings)
    local font = build_font(settings.font)
    if font then
        config.font = font
    end

    if settings.font_size then
        config.font_size = settings.font_size
    end

    if settings.color_scheme then
        config.color_scheme = settings.color_scheme
    end

    if settings.command_palette_font_size then
        config.command_palette_font_size = settings.command_palette_font_size
    end

    local window_frame_font = build_font(settings.window_frame_font or settings.font)
    if window_frame_font or settings.window_frame_font_size then
        config.window_frame = config.window_frame or {}
        if window_frame_font then
            config.window_frame.font = window_frame_font
        end
        if settings.window_frame_font_size then
            config.window_frame.font_size = settings.window_frame_font_size
        end
    end

    if settings.default_domain then
        config.default_domain = settings.default_domain
    end
end

function local_overrides.load(settings_path)
    local local_settings_path = settings_path or (wezterm.config_dir .. '/local/init.lua')
    local settings = load_settings(local_settings_path)
    loaded_settings = settings
    loaded_state_file = resolve_path(settings.state_file or DEFAULT_STATE_FILE)
    has_legacy_local_config = settings.local_config ~= nil
    background_cycle.images = nil
    background_cycle.next_index = 1
    background_cycle.image_dir = nil

    if settings.local_config then
        return {
            local_config = settings.local_config,
            state_file = loaded_state_file,
        }
    end

    local config = wezterm.config_builder()
    local state = state_manager.read_state(loaded_state_file)
    if state.current_background_image ~= nil then
        state.current_background_image = nil
        state_manager.write_state(state, loaded_state_file)
    end

    apply_personal_settings(config, settings)

    if state.use_ligatures then
        config.harfbuzz_features = { 'calt=0' }
    end

    return {
        local_config = config,
        state_file = loaded_state_file,
    }
end

function local_overrides.sync_window_background(window)
    if has_legacy_local_config or not loaded_settings or not loaded_state_file then
        return
    end

    local state = state_manager.read_state(loaded_state_file)
    if state.current_background_image ~= nil then
        state.current_background_image = nil
        state_manager.write_state(state, loaded_state_file)
    end

    apply_background(window, loaded_settings, state)
end

return local_overrides
