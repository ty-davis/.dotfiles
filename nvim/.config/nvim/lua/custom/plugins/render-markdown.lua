return {
  repo = Gh 'MeanderingProgrammer/render-markdown.nvim',
  requires = {
    Gh 'nvim-treesitter/nvim-treesitter',
    Gh 'nvim-tree/nvim-web-devicons',
  },
  setup = function()
    require('render-markdown').setup({
      file_types = { 'markdown', 'copilot-chat' },
    })
  end
}
