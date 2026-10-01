return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      window = {
        width = 40,
        auto_expand_width = true,
        mappings = {
          -- Neo-tree-only wrap toggle (applies to the Neo-tree window).
          ["W"] = { "toggle_wrap", desc = "toggle wrap" },
        },
      },
      default_component_configs = {
        container = {
          enable_character_fade = false,
        },
      },
      commands = {
        toggle_wrap = function(state)
          vim.g.neotree_wrap_on = not vim.g.neotree_wrap_on
          local wins = {}
          if state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
            wins = { state.winid }
          else
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
              if ok and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
                table.insert(wins, win)
              end
            end
          end
          for _, win in ipairs(wins) do
            vim.wo[win].wrap = vim.g.neotree_wrap_on
            vim.wo[win].linebreak = vim.g.neotree_wrap_on
            vim.wo[win].breakindent = vim.g.neotree_wrap_on
            if vim.g.neotree_wrap_on then
              vim.wo[win].showbreak = "↪ "
            else
              vim.wo[win].showbreak = ""
            end
          end
          print("Neo-tree wrap " .. (vim.g.neotree_wrap_on and "ON" or "OFF"))
        end,
      },
      -- Neo-tree forces `nowrap` on buffer_enter / window_after_open,
      -- so re-apply the toggled state after its own setup runs.
      -- Static shortcut hint (winbar): same text regardless of wrap state.
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.schedule(function()
              pcall(function()
                vim.wo.winbar = " W:wrap  ?:help  i:details "
              end)
              if vim.g.neotree_wrap_on then
                vim.wo.wrap = true
                vim.wo.linebreak = true
                vim.wo.breakindent = true
                vim.wo.showbreak = "↪ "
              end
            end)
          end,
        },
        {
          event = "neo_tree_window_after_open",
          handler = function()
            vim.schedule(function()
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
                if ok and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
                  pcall(function()
                    vim.wo[win].winbar = " W:wrap  ?:help  i:details "
                  end)
                  if vim.g.neotree_wrap_on then
                    vim.wo[win].wrap = true
                    vim.wo[win].linebreak = true
                    vim.wo[win].breakindent = true
                    vim.wo[win].showbreak = "↪ "
                  end
                end
              end
            end)
          end,
        },
      },
    },
    config = function(_, opts)
      vim.g.neotree_wrap_on = vim.g.neotree_wrap_on or false
      require("neo-tree").setup(opts)
    end,
  },
  {
    "Crysthamus/nvim-file-operations",
    -- branch = "compat" -- if you are on Neovim <= 0.10
    dependencies = {
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("nvim-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
