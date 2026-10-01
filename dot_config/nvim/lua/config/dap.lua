-- ============================================================================
-- nvim-dap configuration
-- ============================================================================

local ok, dap = pcall(require, "dap")
if not ok then
  return
end

local uv = vim.uv or vim.loop

-- ============================================================================
-- Paths
-- ============================================================================

local mason_dir = vim.fn.stdpath("data") .. "/mason"
local mason_packages = mason_dir .. "/packages"


local function mason_bin(path)
  return mason_dir .. "/bin/" .. path
end


local function mason_package(name, path)
  return mason_packages .. "/" .. name .. "/" .. path
end


local function executable(path)
  return path and vim.fn.executable(path) == 1
end


local function file_exists(path)
  return path and vim.fn.filereadable(path) == 1
end


-- ============================================================================
-- Logging
-- ============================================================================

dap.set_log_level("INFO")


-- ============================================================================
-- Breakpoint signs
-- ============================================================================

vim.fn.sign_define("DapBreakpoint", {
  text = "●",
  texthl = "DiagnosticError",
  linehl = "",
  numhl = "",
})

vim.fn.sign_define("DapBreakpointCondition", {
  text = "◆",
  texthl = "DiagnosticWarn",
  linehl = "",
  numhl = "",
})

vim.fn.sign_define("DapBreakpointRejected", {
  text = "○",
  texthl = "DiagnosticError",
  linehl = "",
  numhl = "",
})

vim.fn.sign_define("DapLogPoint", {
  text = "◆",
  texthl = "DiagnosticInfo",
  linehl = "",
  numhl = "",
})

vim.fn.sign_define("DapStopped", {
  text = "▶",
  texthl = "DiagnosticInfo",
  linehl = "DapStoppedLine",
  numhl = "",
})


-- ============================================================================
-- Mason / mason-nvim-dap
-- ============================================================================

pcall(function()
  require("mason").setup()
end)

pcall(function()
  require("mason-nvim-dap").setup({
    automatic_installation = false,

    ensure_installed = {
      "js-debug-adapter",
      "codelldb",
      "delve",
      "php-debug-adapter",
      "local-lua-debugger-vscode",
    },

    handlers = {
      function(config)
        require("mason-nvim-dap").default_setup(config)
      end,
    },
  })
end)


-- ============================================================================
-- Python / debugpy
-- ============================================================================

local python_adapter

local debugpy_adapter = mason_package(
  "debugpy",
  "venv/bin/python"
)

if executable(debugpy_adapter) then
  python_adapter = {
    type = "executable",
    command = debugpy_adapter,
    args = {
      "-m",
      "debugpy.adapter",
    },
  }
elseif vim.fn.executable("python3") == 1 then
  -- Works when debugpy is installed in the user's Python environment.
  python_adapter = {
    type = "executable",
    command = "python3",
    args = {
      "-m",
      "debugpy.adapter",
    },
  }
end

if python_adapter then
  dap.adapters.python = python_adapter
end


-- ============================================================================
-- JavaScript / TypeScript / React / Vue
-- ============================================================================

local js_debug = mason_bin("js-debug-adapter")

if file_exists(js_debug) or executable(js_debug) then
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = {
      command = js_debug,
      args = {
        "${port}",
      },
    },
  }

  dap.adapters["pwa-chrome"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = {
      command = js_debug,
      args = {
        "${port}",
      },
    },
  }

  -- Compatibility aliases.
  dap.adapters.node = dap.adapters["pwa-node"]
  dap.adapters.chrome = dap.adapters["pwa-chrome"]
end


-- ============================================================================
-- C / C++ / Rust - codelldb
-- ============================================================================

local codelldb = mason_bin("codelldb")

if executable(codelldb) then
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb,
      args = {
        "--port",
        "${port}",
      },
    },
  }
end


-- ============================================================================
-- Go - delve
-- ============================================================================

local delve = mason_bin("dlv")

if executable(delve) then
  dap.adapters.delve = {
    type = "server",
    port = "${port}",
    executable = {
      command = delve,
      args = {
        "dap",
        "-l",
        "127.0.0.1:${port}",
      },
    },
  }
end


-- ============================================================================
-- Lua - local-lua-debugger-vscode
-- ============================================================================

local lua_debugger = mason_bin("local-lua-debugger-vscode")

if executable(lua_debugger) then
  dap.adapters["local-lua"] = {
    type = "executable",
    command = lua_debugger,
    args = {
      "extension",
    },
  }
end


-- ============================================================================
-- PHP - php-debug-adapter
-- ============================================================================

local php_debug = mason_bin("php-debug-adapter")

if executable(php_debug) then
  dap.adapters.php = {
    type = "executable",
    command = php_debug,
  }
end


-- ============================================================================
-- Default DAP configurations
--
-- These are FALLBACKS.
--
-- If .vscode/launch.json exists, F5 will use that instead.
-- ============================================================================


-- --------------------------------------------------------------------------
-- JavaScript
-- --------------------------------------------------------------------------

dap.configurations.javascript = {
  {
    name = "Node: Current File",
    type = "pwa-node",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },

  {
    name = "Node: Attach :9229",
    type = "pwa-node",
    request = "attach",
    address = "127.0.0.1",
    port = 9229,
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },
}


-- --------------------------------------------------------------------------
-- TypeScript
-- --------------------------------------------------------------------------

dap.configurations.typescript = {
  {
    name = "Node: Current File",
    type = "pwa-node",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },

  {
    name = "Node: Attach :9229",
    type = "pwa-node",
    request = "attach",
    address = "127.0.0.1",
    port = 9229,
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },
}


-- --------------------------------------------------------------------------
-- React JavaScript
-- --------------------------------------------------------------------------

dap.configurations.javascriptreact = {
  {
    name = "React / Node: Current File",
    type = "pwa-node",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },
}


-- --------------------------------------------------------------------------
-- React TypeScript
-- --------------------------------------------------------------------------

dap.configurations.typescriptreact = {
  {
    name = "React / Node: Current File",
    type = "pwa-node",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },
}


-- --------------------------------------------------------------------------
-- Vue
-- --------------------------------------------------------------------------

dap.configurations.vue = {
  {
    name = "Vue / Node: Current File",
    type = "pwa-node",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  },
}


-- --------------------------------------------------------------------------
-- Python
-- --------------------------------------------------------------------------

dap.configurations.python = {
  {
    name = "Python: Current File",
    type = "python",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    justMyCode = false,
  },

  {
    name = "Python: Module",
    type = "python",
    request = "launch",
    module = function()
      return vim.fn.input("Module: ")
    end,
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    justMyCode = false,
  },

  {
    name = "Python: Attach :5678",
    type = "python",
    request = "attach",
    connect = {
      host = "127.0.0.1",
      port = 5678,
    },
    justMyCode = false,
  },
}


-- --------------------------------------------------------------------------
-- Go
-- --------------------------------------------------------------------------

dap.configurations.go = {
  {
    name = "Go: Debug Package",
    type = "delve",
    request = "launch",
    program = "${workspaceFolder}",
  },

  {
    name = "Go: Debug Current File",
    type = "delve",
    request = "launch",
    program = "${file}",
  },

  {
    name = "Go: Attach :2345",
    type = "delve",
    request = "attach",
    mode = "remote",
    remotePath = "",
    port = 2345,
    host = "127.0.0.1",
  },
}


-- --------------------------------------------------------------------------
-- C
-- --------------------------------------------------------------------------

dap.configurations.c = {
  {
    name = "C/C++: Launch",
    type = "codelldb",
    request = "launch",

    program = function()
      return vim.fn.input(
        "Executable: ",
        vim.fn.getcwd() .. "/",
        "file"
      )
    end,

    cwd = "${workspaceFolder}",

    stopOnEntry = false,

    runInTerminal = true,
  },
}


-- --------------------------------------------------------------------------
-- C++
-- --------------------------------------------------------------------------

dap.configurations.cpp = {
  {
    name = "C++: Launch",
    type = "codelldb",
    request = "launch",

    program = function()
      return vim.fn.input(
        "Executable: ",
        vim.fn.getcwd() .. "/",
        "file"
      )
    end,

    cwd = "${workspaceFolder}",

    stopOnEntry = false,

    runInTerminal = true,
  },
}


-- --------------------------------------------------------------------------
-- Rust
-- --------------------------------------------------------------------------

dap.configurations.rust = {
  {
    name = "Rust: Launch",
    type = "codelldb",
    request = "launch",

    program = function()
      local cwd = vim.fn.getcwd()

      local cargo_name

      local cargo_toml = cwd .. "/Cargo.toml"

      if file_exists(cargo_toml) then
        for line in io.lines(cargo_toml) do
          local name = line:match("^name%s*=%s*[\"']([^\"']+)")
          if name then
            cargo_name = name
            break
          end
        end
      end

      if cargo_name then
        local binary = cwd .. "/target/debug/" .. cargo_name

        if file_exists(binary) or executable(binary) then
          return binary
        end
      end

      return vim.fn.input(
        "Executable: ",
        cwd .. "/target/debug/",
        "file"
      )
    end,

    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    runInTerminal = true,
  },
}


-- --------------------------------------------------------------------------
-- Lua
-- --------------------------------------------------------------------------

dap.configurations.lua = {
  {
    name = "Lua: Current File",
    type = "local-lua",
    request = "launch",
    cwd = "${workspaceFolder}",
    program = {
      command = "${file}",
      args = {},
    },
  },
}


-- --------------------------------------------------------------------------
-- PHP
-- --------------------------------------------------------------------------

dap.configurations.php = {
  {
    name = "PHP: Current File",
    type = "php",
    request = "launch",
    port = 9003,
    cwd = "${workspaceFolder}",
    program = "${file}",
    runtimeExecutable = "php",
  },

  {
    name = "PHP: Listen for Xdebug",
    type = "php",
    request = "launch",
    port = 9003,
  },
}


-- ============================================================================
-- VS Code launch.json support
-- ============================================================================

local vscode = require("dap.ext.vscode")

-- Map VS Code debugger types to Neovim filetypes.
--
-- This is particularly important for:
--
--   typescriptreact
--   javascriptreact
--   typescript
--   javascript
--   vue
--
-- because VS Code launch.json commonly uses:
--
--   "type": "node"
--   "type": "pwa-node"
--
local vscode_type_to_filetypes = {
  node = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },

  ["pwa-node"] = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },

  chrome = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },

  ["pwa-chrome"] = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },

  python = {
    "python",
  },

  debugpy = {
    "python",
  },

  delve = {
    "go",
  },

  codelldb = {
    "c",
    "cpp",
    "rust",
  },

  cppdbg = {
    "c",
    "cpp",
  },

  php = {
    "php",
  },

  ["local-lua"] = {
    "lua",
  },
}


-- ============================================================================
-- Find nearest .vscode/launch.json
-- ============================================================================

local function dap_find_launch_json()
  local path = vim.api.nvim_buf_get_name(0)

  -- Neo-tree / unnamed buffers don't give us a useful source file.
  if path == "" or vim.bo.filetype == "neo-tree" then
    path = vim.fn.getcwd()
  end

  local start_dir

  if vim.fn.isdirectory(path) == 1 then
    start_dir = path
  else
    start_dir = vim.fs.dirname(path)
  end

  if not start_dir or start_dir == "" then
    start_dir = vim.fn.getcwd()
  end

  local result = vim.fs.find(".vscode/launch.json", {
    path = start_dir,
    upward = true,
    type = "file",
  })

  return result[1]
end


-- ============================================================================
-- Load .vscode/launch.json
-- ============================================================================

local function dap_load_launch_json()
  local launch_json = dap_find_launch_json()

  if not launch_json then
    return nil, {}
  end

  -- Remove configurations previously loaded from launch.json.
  --
  -- This prevents stale configurations if you move between projects.
  for _, filetype in ipairs({
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "python",
    "go",
    "c",
    "cpp",
    "rust",
    "php",
    "lua",
  }) do
    -- Keep the original fallback configurations.
    --
    -- load_launchjs() will append/replace configurations as appropriate.
  end

  local ok, err = pcall(function()
    vscode.load_launchjs(
      launch_json,
      vscode_type_to_filetypes
    )
  end)

  if not ok then
    vim.notify(
      "Failed to load " .. launch_json .. "\n" .. tostring(err),
      vim.log.levels.ERROR
    )

    return launch_json, {}
  end

  local ft = vim.bo.filetype
  local configs = dap.configurations[ft] or {}

  return launch_json, configs
end


-- ============================================================================
-- Find launch.json configurations
-- ============================================================================

local function dap_launch_configs()
  local launch_json = dap_find_launch_json()

  if not launch_json then
    return nil, nil
  end

  local ok, err = pcall(function()
    vscode.load_launchjs(
      launch_json,
      vscode_type_to_filetypes
    )
  end)

  if not ok then
    vim.notify(
      "Could not load launch.json:\n" .. tostring(err),
      vim.log.levels.ERROR
    )

    return launch_json, {}
  end

  local configs = dap.configurations[vim.bo.filetype] or {}

  return launch_json, configs
end


-- ============================================================================
-- Smart F5
--
-- Priority:
--
--   1. Existing session -> continue
--   2. .vscode/launch.json -> use it
--   3. Native dap.configurations -> use them
--   4. Nothing -> notify
-- ============================================================================

local function dap_smart_launch()
  -- Never try to debug Neo-tree itself.
  if vim.bo.filetype == "neo-tree" then
    vim.notify(
      "Open a source file before pressing F5",
      vim.log.levels.WARN
    )
    return
  end

  -- Existing session.
  if dap.session() then
    dap.continue()
    return
  end

  -- -------------------------------------------------------------------------
  -- .vscode/launch.json
  -- -------------------------------------------------------------------------

  local launch_json, launch_configs = dap_launch_configs()

  if launch_json then
    if #launch_configs == 0 then
      vim.notify(
        "Found " .. launch_json
          .. " but no configuration matches filetype: "
          .. vim.bo.filetype,
        vim.log.levels.WARN
      )

      -- Give Telescope a chance to show anything loaded.
      local telescope_ok = pcall(function()
        require("telescope").extensions.dap.configurations()
      end)

      if not telescope_ok then
        vim.notify(
          "No matching DAP configuration found",
          vim.log.levels.WARN
        )
      end

      return
    end

    -- Exactly one launch.json configuration.
    if #launch_configs == 1 then
      dap.run(launch_configs[1])
      return
    end

    -- Multiple launch.json configurations.
    vim.ui.select(launch_configs, {
      prompt = "DAP configuration from .vscode/launch.json:",
      format_item = function(config)
        local name = config.name or "Unnamed"
        local request = config.request or ""
        local type = config.type or ""

        return string.format(
          "%s  [%s/%s]",
          name,
          type,
          request
        )
      end,
    }, function(config)
      if config then
        dap.run(config)
      end
    end)

    return
  end

  -- -------------------------------------------------------------------------
  -- Native DAP fallback
  -- -------------------------------------------------------------------------

  local configs = dap.configurations[vim.bo.filetype]

  if not configs or #configs == 0 then
    vim.notify(
      "No DAP configuration for filetype: "
        .. vim.bo.filetype,
      vim.log.levels.WARN
    )

    return
  end

  if #configs == 1 then
    dap.run(configs[1])
    return
  end

  vim.ui.select(configs, {
    prompt = "DAP configuration:",
    format_item = function(config)
      return string.format(
        "%s  [%s/%s]",
        config.name or "Unnamed",
        config.type or "",
        config.request or ""
      )
    end,
  }, function(config)
    if config then
      dap.run(config)
    end
  end)
end


-- ============================================================================
-- Keymaps
-- ============================================================================

vim.keymap.set("n", "<F5>", dap_smart_launch, {
  desc = "DAP: Smart Launch",
})

vim.keymap.set("n", "<F6>", dap.pause, {
  desc = "DAP: Pause",
})

vim.keymap.set("n", "<F7>", dap.terminate, {
  desc = "DAP: Terminate",
})

vim.keymap.set("n", "<F8>", dap.step_over, {
  desc = "DAP: Step Over",
})

vim.keymap.set("n", "<F9>", dap.step_into, {
  desc = "DAP: Step Into",
})

vim.keymap.set("n", "<F10>", dap.step_out, {
  desc = "DAP: Step Out",
})

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {
  desc = "DAP: Toggle Breakpoint",
})

vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, {
  desc = "DAP: Conditional Breakpoint",
})

vim.keymap.set("n", "<leader>dl", function()
  dap.set_breakpoint(
    nil,
    nil,
    vim.fn.input("Log message: ")
  )
end, {
  desc = "DAP: Log Point",
})

vim.keymap.set("n", "<leader>dr", dap.repl.open, {
  desc = "DAP: REPL",
})

vim.keymap.set("n", "<leader>dc", dap.continue, {
  desc = "DAP: Continue",
})

vim.keymap.set("n", "<leader>di", dap.step_into, {
  desc = "DAP: Step Into",
})

vim.keymap.set("n", "<leader>do", dap.step_over, {
  desc = "DAP: Step Over",
})

vim.keymap.set("n", "<leader>dO", dap.step_out, {
  desc = "DAP: Step Out",
})

vim.keymap.set("n", "<leader>dt", dap.terminate, {
  desc = "DAP: Terminate",
})

vim.keymap.set("n", "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, {
  desc = "DAP: Hover",
})

vim.keymap.set({ "n", "v" }, "<leader>de", function()
  require("dapui").eval()
end, {
  desc = "DAP: Evaluate",
})


-- ============================================================================
-- DAP UI
-- ============================================================================

local dapui_ok, dapui = pcall(require, "dapui")

if dapui_ok then
  dapui.setup({
    layouts = {
      {
        elements = {
          {
            id = "scopes",
            size = 0.25,
          },
          {
            id = "breakpoints",
            size = 0.25,
          },
          {
            id = "stacks",
            size = 0.25,
          },
          {
            id = "watches",
            size = 0.25,
          },
        },
        size = 40,
        position = "left",
      },

      {
        elements = {
          {
            id = "repl",
            size = 0.5,
          },
          {
            id = "console",
            size = 0.5,
          },
        },
        size = 10,
        position = "bottom",
      },
    },

    controls = {
      enabled = true,
      element = "repl",
      icons = {
        pause = "⏸",
        play = "▶",
        step_into = "↓",
        step_over = "→",
        step_out = "↑",
        step_back = "←",
        run_last = "↻",
        terminate = "■",
        disconnect = "⏏",
      },
    },

    floating = {
      border = "rounded",
      mappings = {
        close = { "q", "<Esc>" },
      },
    },

    windows = {
      indent = 1,
    },

    render = {
      max_type_length = nil,
      max_value_lines = 100,
    },
  })

  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end

  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end

  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  vim.keymap.set("n", "<leader>du", dapui.toggle, {
    desc = "DAP: Toggle UI",
  })
end


-- ============================================================================
-- Virtual text
-- ============================================================================

pcall(function()
  require("nvim-dap-virtual-text").setup({
    enabled = true,
    enabled_commands = true,

    highlight_changed_variables = true,
    highlight_new_as_changed = true,

    show_stop_reason = true,
    commented = false,

    only_first_definition = false,
    all_references = false,

    virt_text_pos = "eol",
    virt_lines = false,

    show_variable = function()
      return true
    end,

    display_callback = function(variable)
      return " " .. variable
    end,
  })
end)


-- ============================================================================
-- Telescope DAP
-- ============================================================================

pcall(function()
  require("telescope").load_extension("dap")
end)

vim.keymap.set("n", "<leader>dC", function()
  local ok_telescope = pcall(function()
    require("telescope").extensions.dap.configurations()
  end)

  if not ok_telescope then
    vim.notify(
      "Telescope DAP extension is not available",
      vim.log.levels.WARN
    )
  end
end, {
  desc = "DAP: Configurations",
})

vim.keymap.set("n", "<leader>dlb", function()
  local ok_telescope = pcall(function()
    require("telescope").extensions.dap.list_breakpoints()
  end)

  if not ok_telescope then
    vim.notify(
      "Telescope DAP extension is not available",
      vim.log.levels.WARN
    )
  end
end, {
  desc = "DAP: List Breakpoints",
})

vim.keymap.set("n", "<leader>dv", function()
  local ok_telescope = pcall(function()
    require("telescope").extensions.dap.variables()
  end)

  if not ok_telescope then
    vim.notify(
      "Telescope DAP extension is not available",
      vim.log.levels.WARN
    )
  end
end, {
  desc = "DAP: Variables",
})


-- ============================================================================
-- Next.js helper
--
-- Optional convenience mappings. Your .vscode/launch.json remains the
-- authoritative configuration when it exists.
-- ============================================================================

local function debug_nextjs()
  if not executable(js_debug) then
    vim.notify(
      "js-debug-adapter not found",
      vim.log.levels.ERROR
    )
    return
  end

  dap.run({
    type = "pwa-node",
    request = "attach",
    name = "Next.js Node :9230",
    address = "127.0.0.1",
    port = 9230,
    cwd = vim.fn.getcwd(),

    sourceMaps = true,

    skipFiles = {
      "<node_internals>/**",
      "**/node_modules/**",
    },
  })
end

vim.keymap.set("n", "<leader>dn", debug_nextjs, {
  desc = "DAP: Attach Next.js :9230",
})


-- ============================================================================
-- Diagnostics / information
-- ============================================================================

vim.api.nvim_create_user_command("DapCheck", function()
  local ft = vim.bo.filetype
  local launch_json = dap_find_launch_json()

  print("=== DAP Check ===")
  print("Filetype: " .. ft)

  if launch_json then
    print("launch.json: " .. launch_json)
  else
    print("launch.json: none")
  end

  print("")
  print("Adapters:")

  local adapter_names = vim.tbl_keys(dap.adapters)
  table.sort(adapter_names)

  for _, name in ipairs(adapter_names) do
    print("  " .. tostring(name))
  end

  print("")
  print("Configurations for " .. ft .. ":")

  local configs = dap.configurations[ft] or {}

  if #configs == 0 then
    print("  none")
  else
    for i, config in ipairs(configs) do
      print(string.format(
        "  %d. %s [%s/%s]",
        i,
        config.name or "Unnamed",
        config.type or "",
        config.request or ""
      ))
    end
  end
end, {
  desc = "Check DAP configuration",
})


-- ============================================================================
-- Done
-- ============================================================================

vim.notify("nvim-dap loaded", vim.log.levels.DEBUG)
