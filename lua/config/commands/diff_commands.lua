local utils = require('utils')

local hdiff_bufs_counter = 0

---@class DiffBufOpts
---@field content string|table<string> the content of the buffer
---@field buffer_name? string optional name to use for the buffer (if missing, will generate one automatically)
---@field file_type? string the file type to use for the buffer

---@param buf_name? string buffer name
---@param filetype? string filetype to set for the buffer (to enable syntax highlighting)
local function convert_current_buffer_to_diff_buffer(buf_name, filetype)
  if buf_name == nil or buf_name == '' then
    hdiff_bufs_counter = hdiff_bufs_counter + 1
    buf_name = tostring(hdiff_bufs_counter)
  end

  vim.cmd('file cdiff://' .. buf_name)
  vim.opt_local.buftype = 'nofile'
  vim.opt_local.bufhidden = 'hide'
  vim.opt_local.swapfile = false
  if filetype ~= nil and filetype ~= '' then
    vim.opt_local.filetype = filetype
  end
end

local function close_diff_keymap_callback()
  for _, buffer in ipairs(vim.fn.getbufinfo()) do
    if buffer.name:match('^cdiff://') ~= nil then
      vim.api.nvim_buf_delete(buffer.bufnr, { force = true })
    end
  end
end

---Create a new tab with vertical split and compare the buffers in diff mode.
---
---@param first_buf_opts DiffBufOpts
---@param second_buf_opts DiffBufOpts
local function diff(first_buf_opts, second_buf_opts)
  vim.cmd('tabnew')
  convert_current_buffer_to_diff_buffer(first_buf_opts.buffer_name, first_buf_opts.file_type)

  local buffer_content = first_buf_opts.content
  if type(buffer_content) == 'string' then
    buffer_content = vim.split(buffer_content or '', '\n')
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)

  vim.cmd('vsplit')
  vim.cmd('enew')
  convert_current_buffer_to_diff_buffer(second_buf_opts.buffer_name, second_buf_opts.file_type)

  buffer_content = second_buf_opts.content
  if type(buffer_content) == 'string' then
    buffer_content = vim.split(buffer_content or '', '\n')
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)

  -- Run diffthis in all windows
  vim.cmd('windo diffthis')

  for _, buf in ipairs(vim.fn.getbufinfo()) do
    if buf.name:match('^cdiff://') ~= nil then
      vim.api.nvim_buf_set_keymap(buf.bufnr, 'n', '<C-c>', '', { silent = true, callback = close_diff_keymap_callback })
      vim.api.nvim_buf_set_keymap(buf.bufnr, 'n', 'q', '', { silent = true, callback = close_diff_keymap_callback })
    end
  end
end

---@param range boolean if `true` will copy the highlighted text instead of the whole buffer
local function diff_with_clipboard(range)
  local clipboard_content = vim.fn.getreg('+')
  if clipboard_content == nil or clipboard_content == '' then
    vim.notify('Clipboard is empty, copy something first!', vim.log.levels.WARN)
    return
  end

  local buffer_name = vim.api.nvim_buf_get_name(0)
  ---@type string|nil
  local filetype = vim.bo.filetype

  if type(filetype) == 'table' and #filetype > 0 then
    filetype = filetype[1]
  elseif not (type(filetype) == 'string' and filetype ~= '') then
    filetype = nil
  end
  if range then
    -- Yank visual selection to z register
    vim.cmd('normal! gv"zy')
  else
    -- Yank current buffer content to z register
    vim.cmd('normal! ggVG"zy')
  end

  -- Retrieve the yanked text from the register
  local buffer_contennt = vim.fn.getreg('z', true)

  ---@type DiffBufOpts
  local current_buf_opts = {
    content = buffer_contennt,
    buffer_name = buffer_name,
    buffer_filetype = filetype,
  }

  ---@type DiffBufOpts
  local clipboard_buf_opts = {
    buffer_name = 'Clipboard',
    content = clipboard_content,
    buffer_filetype = filetype,
  }

  diff(clipboard_buf_opts, current_buf_opts)
end

vim.api.nvim_create_user_command('DiffToggleIgnoreWhitespace', function()
  if vim.opt.diffopt:find('iwhiteall') then
    vim.opt.diffopt = vim.opt.diffopt:gsub(',?iwhiteall', '')
    vim.notify('Whitespace diff enabled')
  else
    vim.opt.diffopt = vim.opt.diffopt .. ',iwhiteall'
    vim.notify('Whitespace diff disabled')
  end
end, { nargs = 0, desc = 'Toggle ignore all whitespace in diff view' })

vim.api.nvim_create_user_command('DiffClipboard', function()
  diff_with_clipboard(false)
end, { nargs = 0, desc = 'Diff/Compare the current buffer with the content of the clipboard' })

vim.api.nvim_create_user_command('DiffClipboardSelection', function()
  diff_with_clipboard(true)
end, { nargs = 0, range = true, desc = 'Diff/Compare the visually selected text with the content of the clipboard' })

vim.api.nvim_create_user_command('DiffFiles', function()
  utils.pick_file(function(first_file)
    if first_file then
      utils.pick_file(function(second_file)
        if second_file then
          -- vim.notify(first_file .. ' <> ' .. second_file)
          diff({
            buffer_name = first_file,
            content = vim.fn.readfile(first_file),
          }, {
            buffer_name = second_file,
            content = vim.fn.readfile(second_file),
          })
        end
      end, { prompt_title = 'Pick second file' })
    else
    end
  end, { prompt_title = 'Pick first file' })
end, { desc = 'Select two files and compare them (diff)' })

-- vim: ts=2 sts=2 sw=2 et
