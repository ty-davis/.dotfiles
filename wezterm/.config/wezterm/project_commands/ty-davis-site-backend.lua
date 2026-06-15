local wezterm = require("wezterm")
local act = wezterm.action


return {
    brief = 'ty-davis-site-backend development',
    action = wezterm.action_callback(function (win, pane)
        local is_windows = wezterm.target_triple:find('windows') ~= nil
        local git_base = wezterm.home_dir .. "/gitLocals/ty-davis-site-backend/"

        local function spawn_dev_tab(cwd_rel, final_cmd, use_venv)
            local cmds = {}
            if use_venv ~= false then
                -- always activate venv from git_base where it lives
                table.insert(cmds, 'cd ' .. git_base)
                if is_windows then
                    table.insert(cmds, './.env/Scripts/Activate.ps1')
                else
                    table.insert(cmds, 'source .env/bin/activate')
                end
            end
            -- cd into the actual target dir (may be same as git_base)
            if cwd_rel ~= git_base then
                table.insert(cmds, 'cd ' .. cwd_rel)
            end
            -- exec only before the final command so the tab process becomes the app
            local cmd_str = table.concat(cmds, ' && ') .. ' && exec ' .. final_cmd

            win:mux_window():spawn_tab {
                cwd = cwd_rel,
                args = { 'bash', '-c', cmd_str },
            }
        end

        spawn_dev_tab(git_base, 'nvim')
        spawn_dev_tab(git_base .. 'backend', 'python manage.py runserver')
        spawn_dev_tab(git_base .. 'backend/core/static', 'npm run watch:css', false)

    end)
}
