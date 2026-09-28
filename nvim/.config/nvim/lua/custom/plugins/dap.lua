local function unique_paths(paths)
  local seen = {}
  local result = {}

  for _, path in ipairs(paths) do
    if path and path ~= '' and not seen[path] then
      seen[path] = true
      table.insert(result, path)
    end
  end

  return result
end

local function find_dotnet_root(start_path)
  local matches = vim.fs.find(function(name) return name:match '%.sln$' or name:match '%.csproj$' end, {
    upward = true,
    path = start_path,
    limit = 1,
    type = 'file',
  })

  return matches[1] and vim.fs.dirname(matches[1]) or nil
end

local function find_candidate_dlls()
  local current_buffer = vim.api.nvim_buf_get_name(0)
  local search_roots = unique_paths {
    current_buffer ~= '' and find_dotnet_root(vim.fs.dirname(current_buffer)) or nil,
    find_dotnet_root(vim.fn.getcwd()),
    vim.fn.getcwd(),
  }

  local candidates = {}
  local seen = {}

  for _, root in ipairs(search_roots) do
    for _, pattern in ipairs { '**/bin/Debug/**/*.dll', '**/bin/Release/**/*.dll' } do
      for _, path in ipairs(vim.fn.globpath(root, pattern, false, true)) do
        if not seen[path] then
          seen[path] = true
          table.insert(candidates, path)
        end
      end
    end
  end

  table.sort(candidates)
  return candidates
end

local function pick_dll()
  local dap = require 'dap'
  local candidates = find_candidate_dlls()

  if #candidates == 0 then
    local path = vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/', 'file')
    return path ~= '' and path or dap.ABORT
  end

  if #candidates == 1 then return candidates[1] end

  return coroutine.create(function(dap_run_co)
    vim.ui.select(candidates, {
      prompt = 'Select .NET debug target',
      format_item = function(path)
        return ('%s - %s'):format(vim.fs.basename(path), vim.fn.fnamemodify(path, ':h:.'))
      end,
    }, function(choice)
      coroutine.resume(dap_run_co, choice or dap.ABORT)
    end)
  end)
end

return {
  repo = Gh 'mfussenegger/nvim-dap',
  requires = {
    Gh 'jay-babu/mason-nvim-dap.nvim',
    Gh 'mason-org/mason.nvim',
    Gh 'nvim-neotest/nvim-nio',
    Gh 'rcarriga/nvim-dap-ui',
  },
  setup = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', function() dap.step_into() end, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', function() dap.step_over() end, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', function() dap.step_out() end, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<F7>', function() dapui.toggle() end, { desc = 'Debug: Toggle UI' })
    vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = 'Debug: Toggle [B]reakpoint' })
    vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Conditional [B]reakpoint' })
    vim.keymap.set('n', '<leader>dr', function() dap.repl.open() end, { desc = 'Debug: Open [R]EPL' })

    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      icons = { expanded = 'v', collapsed = '>', current_frame = '*' },
      controls = {
        icons = {
          pause = '||',
          play = '>',
          step_into = '->',
          step_over = '=>',
          step_out = '<-',
          step_back = 'b',
          run_last = '>>',
          terminate = '[]',
          disconnect = 'x',
        },
      },
    }

    require('mason-nvim-dap').setup {
      ensure_installed = { 'coreclr' },
      automatic_installation = true,
      handlers = {},
    }

    local coreclr_configurations = {
      {
        type = 'coreclr',
        name = 'NetCoreDbg: Launch',
        request = 'launch',
        cwd = '${workspaceFolder}',
        program = pick_dll,
      },
      {
        type = 'coreclr',
        name = 'NetCoreDbg: Attach',
        request = 'attach',
        cwd = '${workspaceFolder}',
        processId = require('dap.utils').pick_process,
      },
    }

    dap.configurations.cs = vim.deepcopy(coreclr_configurations)
    dap.configurations.fsharp = vim.deepcopy(coreclr_configurations)

    dap.listeners.after.event_initialized.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
  end,
}
