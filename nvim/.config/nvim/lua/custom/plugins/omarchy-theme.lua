-- Loads the colorscheme plugin from the active Omarchy theme.
-- When you run `omarchy theme set "..."`, restarting Neovim picks it up automatically.
-- Omarchy generates a LazyVim-style spec; adapt its theme entry to this vim.pack setup.
local theme_file = vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua'
local ok, specs = pcall(dofile, theme_file)

if not ok or type(specs) ~= 'table' then
  -- init.lua already loads Tokyo Night as the fallback.
  return {}
end

local theme_spec
local colorscheme

for _, spec in ipairs(specs) do
  if type(spec) == 'table' and type(spec[1]) == 'string' then
    if spec[1] == 'LazyVim/LazyVim' then
      colorscheme = spec.opts and spec.opts.colorscheme
    elseif not theme_spec then
      theme_spec = spec
    end
  end
end

if not theme_spec then return {} end

local repo = theme_spec[1]
local plugin_name = theme_spec.name or repo:match '([^/]+)$' or 'aether'
plugin_name = plugin_name:gsub('%.nvim$', '')
colorscheme = colorscheme or plugin_name

local source = repo
if not source:match '^https?://' and not source:match '^git@' and not source:match '^ssh://' then
  source = 'https://github.com/' .. source
end

local colors = (theme_spec.opts and theme_spec.opts.colors) or {}
local separator_fg = colors.muted or colors.dark_fg or colors.fg
local inactive_bg = colors.lighter_bg or colors.dark_bg or colors.bg

-- Use the active palette for separators and inactive status lines. Schedule the
-- overrides after lualine's ColorScheme handler so they are not overwritten.
local function fix_aether_separators()
  if not separator_fg or not inactive_bg then return end

  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = separator_fg })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = separator_fg, bg = inactive_bg })
  vim.api.nvim_set_hl(0, 'lualine_a_inactive', { fg = separator_fg, bg = inactive_bg })
  vim.api.nvim_set_hl(0, 'lualine_b_inactive', { fg = separator_fg, bg = inactive_bg })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('omarchy-winsep', { clear = true }),
  pattern = colorscheme,
  callback = function()
    vim.schedule(fix_aether_separators)
  end,
})

-- Also fix on VimEnter in case ColorScheme fired before lualine was ready
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('omarchy-winsep-enter', { clear = true }),
  once = true,
  callback = function()
    if vim.g.colors_name == colorscheme then
      fix_aether_separators()
    end
  end,
})

return {
  repo = {
    src = source,
    version = theme_spec.branch or theme_spec.version,
    name = theme_spec.name,
  },
  setup = function()
    local theme = require(plugin_name)
    if type(theme.setup) == 'function' then theme.setup(theme_spec.opts or {}) end
    vim.cmd.colorscheme(colorscheme)
  end,
}
