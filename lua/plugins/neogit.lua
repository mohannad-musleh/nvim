-- An interactive and powerful Git interface for Neovim
--
-- https://github.com/NeogitOrg/neogit
--
-- diffview: https://github.com/sindrets/diffview.nvim

return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    {
      'sindrets/diffview.nvim', -- optional - Diff integration
      ---@module 'diffview'
      ---@type DiffviewConfig
      opts = {
        use_icons = false,
        signs = {
          fold_closed = ' ',
          fold_open = ' ',
          done = '✓ ',
        },
        keymaps = {
          disable_defaults = false,
          file_history_panel = {
            {
              'n',
              'q',
              function()
                vim.cmd('DiffviewClose')
              end,
              { desc = 'Close file history view' },
            },
            {
              'n',
              '<C-c>',
              function()
                vim.cmd('DiffviewClose')
              end,
              { desc = 'Close file history view' },
            },
          },
        },
      },
    },
  },
  ---@module "neogit"
  ---@type NeogitConfig
  opts = {
    kind = 'vsplit',
  },
  config = true,
}

-- vim: ts=2 sts=2 sw=2 et
