-- Tools to help create flutter apps in neovim using the native lsp
--
-- https://github.com/nvim-flutter/flutter-tools.nvim
-- Blog: https://medium.com/indian-coder/supercharge-flutter-with-neovim-a-complete-setup-guide-cbe5cbf5b073

local M = {}

if vim.fn.executable('flutter') == 1 then
  M = {
    'nvim-flutter/flutter-tools.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      debugger = {
        enabled = true,
        register_configurations = function(_)
          require('dap').configurations.dart = {}
          require('dap.ext.vscode').load_launchjs()
        end,
      },
    },
  }
end

return M

-- vim: ts=2 sts=2 sw=2 et
