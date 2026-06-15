-- vim.keymap.set('t', '<C-m>', 'maybe so', { noremap = true })
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap = true })
vim.keymap.set('t', '<C-w>', '<C-\\><C-n><C-w>', { noremap = true })
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { noremap = true })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { noremap = true })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { noremap = true })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { noremap = true })


local function terminal_below(count)
  vim.cmd('split')
  vim.cmd('wincmd J')
  vim.cmd('res 15')
  for i=1,count do
    vim.cmd('terminal')
    if i>1 then
      print(i)
      vim.cmd('vs')
      vim.cmd('wincmd l')
      vim.cmd('terminal')
    end
  end
end

local function v_terminal_right(count)
  vim.cmd('vsplit')
  vim.cmd('wincmd L')
  vim.cmd('vert res 50')
  -- vim.cmd('wincmd l')
  for i=1,count do
    vim.cmd('terminal')
    if i>1 then
      vim.cmd('split')
      vim.cmd('wincmd j')
      vim.cmd('terminal')
    end
  end
end

vim.api.nvim_create_user_command('Term', function (args)
  local vertical = false
  if string.match(args.args, '-v') then
    vertical = true
  end

  local term_count = 1
  for k,v in pairs(args.fargs) do
    if tonumber(v) then
      term_count = v
      break
    end
  end

  if vertical then
    v_terminal_right(term_count)
  else
    terminal_below(term_count)
  end
  end, {nargs="*"})

local function send_to_terminal(cmd)
  local term_found = false
  local wins_list = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())

  for _, win in ipairs(wins_list) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      term_found = true
      vim.api.nvim_set_current_win(win)
      break
    end
  end

  if not term_found then
    vim.cmd('Term')
  end
  vim.api.nvim_feedkeys('i' .. cmd .. '\r', 'n', false)
end

local function run_file()
  local uname = vim.uv.os_uname()
  local is_windows = uname.sysname:match("Windows")

  local cmd = ''
  local filename = vim.fn.expand("%:p")
  if vim.bo.filetype == 'python' then
    local python_suffix = ''
    if not is_windows then
      python_suffix = '3'
    end
    cmd = 'python' .. python_suffix .. ' "' .. filename .. '"'
  elseif vim.bo.filetype == 'c' then
    if is_windows then
      cmd = 'gcc "' .. filename .. '" ; ./a.exe'
    else
      cmd = 'gcc "' .. filename .. '" && ./a.out'
    end
  elseif vim.bo.filetype == 'cpp' then
    if is_windows then
      cmd = 'g++ "' .. filename .. '" ; ./a.exe'
    else
      cmd = 'g++ "' .. filename .. '" && ./a.out'
    end
  elseif vim.bo.filetype == 'javascript' then
    cmd = 'node "' .. filename .. '"'
  end
  send_to_terminal(cmd)
end

local function run_script(script_name)
  local uname = vim.uv.os_uname()
  local is_windows = uname.sysname:match("Windows")

  local cmd = ''
  if is_windows then
    cmd = './' .. script_name .. '.ps1'
  else
    cmd = './' .. script_name .. '.sh'
  end
  send_to_terminal(cmd)
end

vim.keymap.set('n', '<leader>rf', function () run_file() end, {desc="[R]un [F]ile"})
vim.keymap.set('n', '<leader>rs', function () run_script('run') end, {desc="[R]un [S]cript"})
vim.keymap.set('n', '<leader>rt', function () run_script('run_test') end, {desc="[R]un [T]est script"})

return {}
