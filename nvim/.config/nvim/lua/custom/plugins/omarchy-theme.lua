-- Loads the colorscheme plugin from the active Omarchy theme.
-- When you run `omarchy theme set "..."`, restarting Neovim picks it up automatically.
-- The theme's neovim.lua is written for LazyVim; we strip the LazyVim entry here.
local theme_file = vim.fn.expand '~/.config/omarchy/current/theme/neovim.lua'
local ok, specs = pcall(dofile, theme_file)

if not ok or type(specs) ~= 'table' then
  -- Fallback if no omarchy theme is active
  return {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight'
    end,
  }
end

-- Make window separators more visible for the aether theme.
-- Uses vim.schedule so our overrides run AFTER lualine's ColorScheme handler.
local function fix_aether_separators()
  vim.api.nvim_set_hl(0, 'WinSeparator',  { fg = '#585b70' })
  vim.api.nvim_set_hl(0, 'StatusLineNC',  { fg = '#7f849c', bg = '#313244' })
  -- lualine inactive statusline groups (lualine overwrites StatusLineNC)
  vim.api.nvim_set_hl(0, 'lualine_a_inactive', { fg = '#7f849c', bg = '#313244' })
  vim.api.nvim_set_hl(0, 'lualine_b_inactive', { fg = '#7f849c', bg = '#313244' })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('omarchy-winsep', { clear = true }),
  pattern = 'aether',
  callback = function()
    vim.schedule(fix_aether_separators)
  end,
})

-- Also fix on VimEnter in case ColorScheme fired before lualine was ready
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('omarchy-winsep-enter', { clear = true }),
  once = true,
  callback = function()
    if vim.g.colors_name == 'aether' then
      fix_aether_separators()
    end
  end,
})

-- local result = {}
-- for _, spec in ipairs(specs) do
--   if type(spec) == 'table' and type(spec[1]) == 'string' and not spec[1]:match '^LazyVim/' then
--     table.insert(result, spec)
--   end
-- end
-- return result
return {}
