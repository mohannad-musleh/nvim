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

-- -Print the range of characters from arg[0] to arg[1] (default to `a` and `z`) in the current cursor position.
vim.api.nvim_create_user_command('PutCharRange', function(opts)
  -- Default values
  local start_char = 'a'
  local end_char = 'z'

  -- Overwrite defaults if arguments are provided
  -- opts.fargs contains arguments split by whitespace
  if #opts.fargs >= 1 then
    start_char = opts.fargs[1]
  end
  if #opts.fargs >= 2 then
    end_char = opts.fargs[2]
  end

  -- Convert single-character strings to their ASCII byte values
  local start_byte = string.byte(start_char)
  local end_byte = string.byte(end_char)

  -- Generate the string
  local s = ''
  for i = start_byte, end_byte do
    s = s .. string.char(i)
  end

  -- Insert the result at the cursor position
  vim.api.nvim_put({ s }, 'c', true, true)
end, {
  nargs = '*', -- Allows 0, 1, or 2 arguments
  desc = 'Generate a character range. Default: a-z',
})

-- vim: ts=2 sts=2 sw=2 et
