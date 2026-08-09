-- Mobile-friendly Neovim configuration
-- Only loaded when running on Termux Android
-- Provides gesture-like navigation and touch-friendly settings

-- Apply mobile-specific settings
vim.g.guicursor = "n-v:block-Cursor/lCursor,i:ver25-Cursor,r:hor20"
vim.opt.signcolumn = "yes"      -- Prevents text shifting
vim.opt.wrap = true             -- Enable word wrap for better readability
vim.opt.linebreak = true        -- Break lines at word boundaries
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.hlsearch = true         -- Highlight search matches
vim.opt.incsearch = true        -- Incremental search
vim.opt.visualbell = true       -- Use visual bell instead of audio
vim.opt.scrolloff = 8           -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8       -- Keep 8 columns left/right of cursor
