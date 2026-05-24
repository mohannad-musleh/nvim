--  See `:help lua-guide-autocommands`

local utils = require 'utils'

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('au-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'help',
  group = vim.api.nvim_create_augroup('HelpMappings', { clear = true }),
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', ']q', ':cnext<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '[q', ':cprev<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  end,
})

