local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

return {
  repo = Gh 'tpope/vim-fugitive',
  setup = function()
    map('n', '<leader>gb', function() require('gitsigns').toggle_current_line_blame() end, '[G]it toggle inline [B]lame')
    map('n', '<leader>gB', '<cmd>Git blame<CR>', '[G]it full [B]lame')
    map('n', '<leader>gl', '<cmd>.Gclog<CR>', '[G]it current [L]ine history')
    map('x', '<leader>gl', ':Gclog<CR>', '[G]it selected [L]ines history')
    map('n', '<leader>gL', '<cmd>Gclog<CR>', '[G]it fi[L]e history')
  end,
}
