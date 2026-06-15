return {
  repo = Gh 'stevearc/aerial.nvim',
  setup = function()
    require("aerial").setup({
      on_attach = function(bufnr)
        -- vim.keymap.set("n", "{", "<cmd>AerialNext<cr>", { buffer = bufnr, desc = "Go to next Aerial symbol"})
        -- vim.keymap.set("n", "{", "<cmd>AerialPrev<cr>", { buffer = bufnr, desc = "Go to prev Aerial symbol"})
      end,
      manage_folds = true,
    })
    vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<cr>", { desc = "Toggle the Aerial nav window"})
  end
}
