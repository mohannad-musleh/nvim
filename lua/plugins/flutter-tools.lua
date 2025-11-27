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
        -- if empty dap will not stop on any exceptions, otherwise it will stop on those specified
        -- see |:help dap.set_exception_breakpoints()| for more info
        exception_breakpoints = {},
        -- Whether to call toString() on objects in debug views like hovers and the
        -- variables list.
        -- Invoking toString() has a performance cost and may introduce side-effects,
        -- although users may expected this functionality. null is treated like false.
        evaluate_to_string_in_debug_views = true,
        -- You can use the `debugger.register_configurations` to register custom runner configuration (for example for different targets or flavor). Plugin automatically registers the default configuration, but you can override it or add new ones.
        -- register_configurations = function(paths)
        --   require("dap").configurations.dart = {
        --     -- your custom configuration
        --   }
        -- end,
      },
    },
  }
end

return M

-- vim: ts=2 sts=2 sw=2 et
