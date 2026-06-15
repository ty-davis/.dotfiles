local single_line_command = '"_50lf\\<space>r\\<CR>"'

local function fix_paragraph(norm)
  if norm then
    vim.api.nvim_command('normal vip')
  end
  vim.api.nvim_command('normal J')
  for _ = 1, 100 do
    -- vim.api.nvim_command('normal 050lf r')
    vim.api.nvim_command('execute "normal" ' .. single_line_command)
  end
  -- vim.api.nvim_command('normal o')
end


vim.keymap.set('n', '<C-n>', function() fix_paragraph(true) end, { noremap = true, desc = "Reformat paragraph"})
vim.keymap.set('v', '<C-n>', function() fix_paragraph(false) end, { noremap = true, desc = "Reformat selection"})

return {}
