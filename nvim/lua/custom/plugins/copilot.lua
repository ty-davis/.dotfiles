return {
  {
    repo = Gh 'zbirenbaum/copilot.lua',
    setup = function()
      require('copilot').setup({
        suggestion = {
          keymap = {
            accept = '<C-h>',
            next = '<C-j>',
            prev = '<C-k>',
          }
        }
      })
    end
  },
  {
    repo = Gh 'CopilotC-Nvim/CopilotChat.nvim',
    requires = {
      Gh 'zbirenbaum/copilot.lua',
      Gh 'nvim-lua/plenary.nvim'
    },
    setup = function()
      require('CopilotChat').setup {
        model = 'claude-sonnet-4.6',
        window = {
          layout = 'float',
          border = 'rounded',
          relative = 'editor',
          width = 0.6,
          height = 0.6,
        },
        mappings = {
          reset = {
            normal = '<leader>ccl',
            callback = function(chat) chat:reset() end,
          },
        },
        prompts = {
          Yarrr = {
            system_prompt = 'You are fascinated by pirates, so please response in pirate speak.',
          },
        },
      }
      -- set some keymaps
      vim.api.nvim_set_keymap('n', '<leader>cc<CR>', '<cmd>lua require("CopilotChat").open()<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', '<leader>ccq', function()
        local input = vim.fn.input 'Quick chat: '
        if input ~= nil then
          require('CopilotChat').ask(input, { context = 'buffer' })
        end
      end, { noremap = true, silent = true, desc = 'CopilotChat - Quick chat' })
    end
  },
}
