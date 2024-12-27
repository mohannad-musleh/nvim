--- A pretty diagnostics, references, telescope results, quickfix and location list to help you solve all the trouble your code is causing.
---
--- https://github.com/folke/trouble.nvim

return {
  'folke/trouble.nvim',
  enabled = true,
  cmd = 'Trouble',
  ---@module "trouble"
  ---@type trouble.Config
  opts = {
    focus = false,
    open_no_results = true,
    max_items = false,
    win = {
      type = 'split',
      position = 'right',
    },
  },
  keys = {
    {
      '<leader>cd',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Diagnostics (Trouble)',
    },
    {
      '<leader>cD',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Buffer Diagnostics (Trouble)',
    },
    {
      '<leader>cs',
      '<cmd>Trouble symbols toggle<cr>',
      desc = 'Symbols (Trouble)',
    },
    {
      '<leader>cl',
      '<cmd>Trouble lsp toggle<cr>',
      desc = 'LSP Definitions / references / ... (Trouble)',
    },
    {
      '<leader>xL',
      '<cmd>Trouble loclist toggle<cr>',
      desc = 'Location List (Trouble)',
    },
    {
      '<leader>xQ',
      '<cmd>Trouble qflist toggle<cr>',
      desc = 'Quickfix List (Trouble)',
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
