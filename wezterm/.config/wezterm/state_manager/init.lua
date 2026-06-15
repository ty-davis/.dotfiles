local wezterm = require('wezterm')
local state_manager = {}

-- local state_file = "C:/Users/tydav/.config/wezterm/local/state.json"

function state_manager.read_state(state_file)
    local f = io.open(state_file, "r")
    if f then
        local lines = f:lines()
        local state = {}
        for line in lines do
            local matches = string.gmatch(line, "(%S+)%s*=%s*(%S+)%s*:%s*(%S+)")
            local key, val, val_type = matches()
            if val_type == "boolean" then
                state[key] = val == "true"
            elseif val_type == "number" then
                state[key] = tonumber(val)
            else
                state[key] = val
            end
        end
        f:close()
        return state
    end
    wezterm.log_error("Couldn't find the state file")
    return {}
end

function state_manager.write_state(state, state_file)
    local f = io.open(state_file, 'w')
    if f then
        for k, v in pairs(state) do
            local line = k .. ' = ' .. tostring(v) .. ' : ' .. type(v) .. '\r\n'
            f:write(line)
        end
        f:close()
    end
end

return state_manager
