return {
  {
    'stevearc/conform.nvim',
    event = 'VeryLazy',
    cmd = { 'ConformInfo' },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
        toml = { 'taplo' },
      },
      -- Format chezmoi templates as their deployed filetype on save.
      -- Other filetypes keep today's no-autoformat behaviour; use :Format.
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype ~= 'gotmpl' then
          return nil
        end
        return { timeout_ms = 2000, lsp_format = 'never' }
      end,
    },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = { 'stylua', 'shfmt', 'taplo' },
      auto_update = false,
    },
  },
}
