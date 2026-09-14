-- VSCode-like debugging (nvim-dap + .vscode/launch.json).
-- Minimal by default; <leader>du toggles the full sidebar UI.
local has_dap, dap = pcall(require, 'dap')
if not has_dap then
  return
end

-- Always capture the full adapter protocol so :DapShowLog is definitive
-- when a session fails (e.g. "debug adapter disconnected").
dap.set_log_level('TRACE')

local mason_dir = vim.fn.stdpath('data') .. '/mason'

-- Signs (gutter icons, ASCII-safe)
vim.fn.sign_define('DapBreakpoint', { text = 'B', texthl = 'DiagnosticError', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = 'C', texthl = 'DiagnosticWarn', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = 'L', texthl = 'DiagnosticInfo', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '>', texthl = 'DiagnosticHint', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = 'R', texthl = 'DiagnosticError', numhl = '' })

-- Auto-install debug adapters via Mason (manual fallback below if a
-- package is missing; guarded so startup never errors).
local has_mason_dap, mason_dap = pcall(require, 'mason-nvim-dap')
if has_mason_dap then
  mason_dap.setup({
    -- NOTE: 'python'/debugpy is intentionally absent: Mason builds its venv
    -- with `python3 -m venv`, which fails without the `python3-venv` system
    -- package (no `ensurepip`). Python debugging uses the user-site debugpy
    -- fallback below instead. If you `sudo apt install python3-venv`, run
    -- `:MasonInstall debugpy` once and the Mason adapter takes precedence.
    ensure_installed = {
      'js-debug-adapter', -- pwa-node / pwa-chrome (JS/TS)
      'codelldb', -- C / C++ / Rust
      'delve', -- Go
      'php-debug-adapter', -- PHP / Xdebug
      'local-lua-debugger-vscode', -- generic Lua
    },
    automatic_installation = true,
    automatic_setup = true,
  })
end

local function mason_bin(rel)
  local p = mason_dir .. rel
  return vim.fn.executable(p) == 1 and p or nil
end

-- Adapters (only override when the Mason binary exists; otherwise the
-- mason-nvim-dap handler already defined them).
local debugpy = mason_dir .. '/packages/debugpy/venv/bin/python'
if dap.adapters.python == nil then
  if vim.fn.executable(debugpy) == 1 then
    -- Mason-managed debugpy (needs `python3-venv` on Debian/Ubuntu;
    -- run `:MasonInstall debugpy` after `sudo apt install python3-venv`).
    dap.adapters.python = { type = 'executable', command = debugpy, args = { '-m', 'debugpy.adapter' } }
  elseif vim.fn.executable('python3') == 1 then
    vim.fn.system("python3 -c 'import debugpy' 2>/dev/null")
    if vim.v.shell_error == 0 then
      -- Fallback: user-site debugpy (`pip install --user debugpy`).
      dap.adapters.python = { type = 'executable', command = 'python3', args = { '-m', 'debugpy.adapter' } }
    end
  end
end

local js_debug = mason_dir .. '/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'
if dap.adapters['pwa-node'] == nil and vim.fn.filereadable(js_debug) == 1 then
  dap.adapters['pwa-node'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = { command = 'node', args = { js_debug, '${port}' } },
  }
  dap.adapters['pwa-chrome'] = dap.adapters['pwa-node']
end

-- VSCode-compat aliases: VSCode recipes commonly use `type: "node"` and
-- `type: "chrome"`, which VSCode maps to its JS debugger internally.
-- nvim-dap requires exact adapter names, so alias them to the
-- Mason-installed js-debug adapters. Lets project .vscode/launch.json
-- files work verbatim without modification.
if dap.adapters['pwa-node'] ~= nil and dap.adapters.node == nil then
  dap.adapters.node = dap.adapters['pwa-node']
end
if dap.adapters['pwa-chrome'] ~= nil and dap.adapters.chrome == nil then
  dap.adapters.chrome = dap.adapters['pwa-chrome']
end

local codelldb = mason_bin('/packages/codelldb/extension/adapter/codelldb')
if codelldb and dap.adapters.codelldb == nil then
  dap.adapters.codelldb = { type = 'server', port = '${port}', executable = { command = codelldb, args = { '--port', '${port}' } } }
end

local delve = mason_bin('/packages/delve/dlv')
if delve and dap.adapters.delve == nil then
  dap.adapters.delve = function(callback, config)
    local stdout = vim.loop.new_pipe(false)
    local handle
    local port = config.port or 38697
    local opts = { stdio = { nil, stdout, nil }, args = { 'dap', '-l', '127.0.0.1:' .. port } }
    handle, _ = vim.loop.spawn(delve, opts, function(code)
      if handle then
        handle:close()
      end
      if code ~= 0 then
        print('delve exited with code ' .. code)
      end
    end)
    assert(handle, 'delve failed to start')
    vim.defer_fn(function()
      callback({ type = 'server', host = '127.0.0.1', port = port })
    end, 100)
  end
end

local local_lua_dir = mason_dir .. '/packages/local-lua-debugger-vscode/extension'
if dap.adapters['local-lua'] == nil and vim.fn.filereadable(local_lua_dir .. '/extension/debugAdapter.js') == 1 then
  dap.adapters['local-lua'] = {
    type = 'executable',
    command = 'node',
    args = { local_lua_dir .. '/extension/debugAdapter.js' },
    enrich_config = function(config, on_config)
      if not config.extensionPath then
        local c = vim.deepcopy(config)
        c.extensionPath = local_lua_dir .. '/'
        on_config(c)
      else
        on_config(config)
      end
    end,
  }
end

local php_adapter = mason_bin('/bin/php-debug-adapter')
if php_adapter and dap.adapters.php == nil then
  dap.adapters.php = { type = 'executable', command = php_adapter }
end
-- php-debug-adapter and any remaining adapters are left to mason-nvim-dap.

-- Fallback configurations (used when there is no .vscode/launch.json,
-- so F5 works out of the box; launch.json entries are appended below).
dap.configurations.python = dap.configurations.python or {
  { type = 'python', request = 'launch', name = 'Launch file', program = '${file}', console = 'integratedTerminal' },
}
-- Covers Next.js / React / Vue / Nuxt: Node (server, SSR, API routes)
-- plus Chrome (client). Start Chrome once with a debugging port, e.g.:
--   google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
-- (chromium / microsoft-edge work the same way), then F5 -> attach.
for _, ft in ipairs({ 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'vue' }) do
  dap.configurations[ft] = dap.configurations[ft] or {
    { type = 'pwa-node', request = 'launch', name = 'Launch file', program = '${file}', cwd = '${workspaceFolder}' },
    { type = 'pwa-node', request = 'attach', name = 'Attach :9229', port = 9229, cwd = '${workspaceFolder}' },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to Next.js server :9230',
      port = 9230,
      cwd = '${workspaceFolder}',
      sourceMaps = true,
    },
    {
      type = 'pwa-chrome',
      request = 'attach',
      name = 'Attach to Chrome :9222',
      port = 9222,
      webRoot = '${workspaceFolder}',
      sourceMaps = true,
    },
    {
      type = 'pwa-chrome',
      request = 'launch',
      name = 'Launch Chrome (dev server)',
      url = function()
        return vim.fn.input('URL: ', 'http://localhost:3000')
      end,
      webRoot = '${workspaceFolder}',
      sourceMaps = true,
    },
  }
end
dap.configurations.lua = dap.configurations.lua or {
  { type = 'local-lua', request = 'launch', name = 'Launch file', program = { lua = 'lua', file = '${file}' } },
}
for _, ft in ipairs({ 'c', 'cpp', 'rust' }) do
  dap.configurations[ft] = dap.configurations[ft] or {
    {
      type = 'codelldb',
      request = 'launch',
      name = 'Launch binary',
      program = function()
        return vim.fn.input('Binary: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    },
  }
end
dap.configurations.go = dap.configurations.go or {
  { type = 'delve', request = 'launch', name = 'Debug file', mode = 'file', program = '${file}' },
  { type = 'delve', request = 'launch', name = 'Debug package', mode = 'test', program = './${relativeFileDirname}' },
}
dap.configurations.php = dap.configurations.php or {
  { type = 'php', request = 'launch', name = 'Listen for Xdebug', port = 9003 },
  { type = 'php', request = 'launch', name = 'Launch current script', program = '${file}', cwd = '${workspaceFolder}', port = 9003 },
}

-- VSCode parity: .vscode/launch.json is read automatically on-demand by
-- nvim-dap's built-in `dap.launch.json` provider (no manual load needed).
-- This table maps launch.json `type` values to filetypes for older
-- nvim-dap versions that still use `load_launchjs`.
pcall(function()
  local vscode = require('dap.ext.vscode')
  vscode.type_to_filetypes = vim.tbl_deep_extend('force', vscode.type_to_filetypes or {}, {
    codelldb = { 'c', 'cpp', 'rust' },
    cpptools = { 'c', 'cpp', 'rust' },
    ['pwa-node'] = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'vue' },
    ['pwa-chrome'] = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'vue' },
    node = { 'javascript', 'typescript' },
    chrome = { 'javascript', 'typescript', 'vue' },
    python = { 'python' },
    debugpy = { 'python' },
    delve = { 'go' },
    go = { 'go' },
    php = { 'php' },
    ['local-lua'] = { 'lua' },
  })
end)

-- Virtual text (inline values; part of the minimal default UI).
pcall(function()
  require('nvim-dap-virtual-text').setup({ commented = true })
end)

-- Full sidebar UI: closed by default, <leader>du toggles.
-- To auto-open like VSCode, uncomment the event_..._dapui_config lines.
local has_dapui, dapui = pcall(require, 'dapui')
if has_dapui then
  dapui.setup()
  -- dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
  dap.listeners.before.event_terminated['dapui_config'] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited['dapui_config'] = function()
    dapui.close()
  end
end

pcall(function()
  require('telescope').load_extension('dap')
end)

-- Keymaps: F-keys like VSCode + <leader>d group (see which-key popup).
local map = vim.keymap.set
map('n', '<F5>', dap.continue, { desc = 'Debug: continue / launch' })
map('n', '<S-F5>', dap.terminate, { desc = 'Debug: stop' })
map('n', '<F10>', dap.step_over, { desc = 'Debug: step over' })
map('n', '<F11>', dap.step_into, { desc = 'Debug: step into' })
map('n', '<S-F11>', dap.step_out, { desc = 'Debug: step out' })
map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: toggle breakpoint' })
map('n', '<leader>dB', function()
  dap.set_breakpoint(vim.fn.input('Condition: '))
end, { desc = 'Debug: conditional breakpoint' })
map('n', '<leader>dlp', function()
  dap.set_breakpoint(nil, nil, vim.fn.input('Log message: '))
end, { desc = 'Debug: log point' })
map('n', '<leader>dc', dap.continue, { desc = 'Debug: continue' })
map('n', '<leader>do', dap.step_over, { desc = 'Debug: step over' })
map('n', '<leader>di', dap.step_into, { desc = 'Debug: step into' })
map('n', '<leader>dO', dap.step_out, { desc = 'Debug: step out' })
map('n', '<leader>dr', dap.repl.toggle, { desc = 'Debug: toggle REPL' })
map('n', '<leader>dl', dap.run_last, { desc = 'Debug: run last' })
map('n', '<leader>dt', dap.terminate, { desc = 'Debug: terminate' })
-- One-shot Next.js full-stack: attaches to the Node server AND Chrome.
-- Prerequisites (terminal 1 & 2, then set breakpoints and hit <leader>dN):
--   google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
--   (chromium / microsoft-edge accept the same flags)
--   NODE_OPTIONS='--inspect=127.0.0.1:9230' npm run dev   (Plugin: port 9230)
local function debug_nextjs()
  dap.run({
    type = 'pwa-node',
    request = 'attach',
    name = 'Next.js server',
    port = 9230,
    cwd = '${workspaceFolder}',
    sourceMaps = true,
  })
  vim.defer_fn(function()
    dap.run({
      type = 'pwa-chrome',
      request = 'attach',
      name = 'Next.js client',
      port = 9222,
      webRoot = '${workspaceFolder}',
      sourceMaps = true,
    })
  end, 1000)
end
map('n', '<leader>dN', debug_nextjs, { desc = 'Debug: Next.js full-stack (server+client)' })
map({ 'n', 'v' }, '<leader>dh', function()
  require('dap.ui.widgets').hover()
end, { desc = 'Debug: hover' })
map({ 'n', 'v' }, '<leader>de', function()
  require('dapui').eval()
end, { desc = 'Debug: eval' })
if has_dapui then
  map('n', '<leader>du', dapui.toggle, { desc = 'Debug: toggle UI' })
end
map('n', '<leader>dd', '<cmd>Telescope dap commands<CR>', { desc = 'Debug: commands' })
map('n', '<leader>dC', '<cmd>Telescope dap configurations<CR>', { desc = 'Debug: configurations' })
map('n', '<leader>dL', '<cmd>Telescope dap list_breakpoints<CR>', { desc = 'Debug: list breakpoints' })
map('n', '<leader>dv', '<cmd>Telescope dap variables<CR>', { desc = 'Debug: variables' })
map('n', '<leader>df', '<cmd>Telescope dap frames<CR>', { desc = 'Debug: frames' })
