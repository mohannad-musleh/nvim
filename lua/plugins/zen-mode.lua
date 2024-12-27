-- Distraction-free coding for Neovim (zen-mode)
--
-- https://github.com/folke/zen-mode.nvim

return {
  'folke/zen-mode.nvim',
  ---@module "zen-mode"
  ---@class ZenOptions
  opts = {
    plugins = {
      gitsigns = { enabled = true }, -- Disable gitsigns
    },
  },
  keys = {
    { '<leader>zz', '<cmd>ZenMode<cr>', desc = 'Toggle Zen Mode' },
    { '<leader>zf', '<cmd>SplitZoom<cr>', desc = 'Toggle Split Fullscreen Mode' },
  },
  config = function(_, opts)
    local zen_mode = require('zen-mode')
    zen_mode.setup(opts)

    vim.api.nvim_create_user_command('SplitZoom', function()
      zen_mode.toggle({ window = { width = 1, height = 1 } })
    end, { desc = 'Make the focused split take full space' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
