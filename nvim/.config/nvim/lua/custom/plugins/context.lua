return {
  repo = Gh 'wellle/context.vim',
  setup = function()
    vim.g.context_enabled = 0
    
    -- some keymaps or something
    vim.keymap.set('n', '<leader>ct', '<cmd>ContextToggle<cr>')
  end
}
