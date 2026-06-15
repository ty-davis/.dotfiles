local wezterm = require('wezterm')
local tydavissitebackend = require('project_commands.ty-davis-site-backend')
local project_commands = {}

function project_commands.get_commands()
    return {
        tydavissitebackend,
    }
end

return project_commands
