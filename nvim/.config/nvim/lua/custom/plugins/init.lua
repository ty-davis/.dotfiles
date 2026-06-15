-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Iterate over all Lua files in the plugins directory and load them
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')

local modules = {}
local repos = {}
local seen = {}

local function add_repo(repo, is_dep)
  -- prefer config from OG declarations, not dependencies
  if repo and (not seen[repo] or seen[repo].is_dep) then
    seen[repo] = { seen = true, is_dep = is_dep }
    table.insert(repos, repo)
  end
end

for file_name, kind in vim.fs.dir(plugins_dir) do
  if kind == 'file' and file_name:match('%.lua$') and file_name ~= 'init.lua' then
    local module_name = file_name:gsub('%.lua$', '')
    local mod = require('custom.plugins.' .. module_name)
    if mod then
      if vim.islist(mod) then
        vim.list_extend(modules, mod)
      else
        table.insert(modules, mod)
      end
    end
  end
end

for _, plugin in ipairs(modules) do
  add_repo(plugin.repo)
  for _, dep in ipairs(plugin.requires or {}) do
    add_repo(dep, true)
  end
end

vim.pack.add(repos)

for _, plugin in ipairs(modules) do
  if type(plugin.setup) == 'function' then
    plugin.setup()
  end
end
