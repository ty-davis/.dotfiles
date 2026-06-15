return {
  repo = Gh 'folke/noice.nvim',
  setup = function()
    require('noice').setup({
      popupmenu = {
        enabled = true,
        backend = "nui",
        kind_icons = {},
      },
      views = {
        popupmenu = {
          relative = "editor",
          position = {row = 8, col = "50%"},
        },
        cmdline_popup = {
          relative = "editor",
          position = {row = "8%", col = "50%" },
        }
      }
    })
  end,
}
