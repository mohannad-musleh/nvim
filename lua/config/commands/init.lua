local utils = require('utils')
local vars = require('vars')

require('config.commands.diff_commands')
require('config.commands.format_commands')

local is_short_listchars = true
vim.api.nvim_create_user_command('ListcharsToggle', function()
  if is_short_listchars then
    is_short_listchars = false
    vim.opt.listchars = vars.long_listchars
  else
    is_short_listchars = true
    vim.opt.listchars = vars.short_listchars
  end
end, { desc = 'Toggle the value of `listchars` between simple/short list and long one.' })

vim.api.nvim_create_user_command('CopyBufferPath', function()
  if utils.copy_buffer_path() ~= nil then
    vim.notify('Current buffer path copied to clipbaord', vim.log.levels.INFO)
  end
end, { nargs = 0, desc = 'Copy current buffer path' })

-- vim: ts=2 sts=2 sw=2 et
