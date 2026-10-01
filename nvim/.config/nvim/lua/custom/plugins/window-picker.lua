return {
  repo = {
    src = Gh 's1n7ax/nvim-window-picker',
    version = vim.version.range '2.*',
  },
  setup = function()
    require('window-picker').setup({
      hint = 'floating-big-letter'
    })

    vim.keymap.set('n', '<leader>w', function()
      local win = require('window-picker').pick_window()
      if win then vim.api.nvim_set_current_win(win) end
    end, { desc = 'Pick a window' })
  end,
}
