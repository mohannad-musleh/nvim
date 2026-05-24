-- Check if the folding is disabled (we do so to manage it through a plugin)
if not vim.g.enable_native_folding then return {} end

_G.my_foldtext = function()
  local foldstart = vim.v.foldstart
  local line_count = vim.v.foldend - foldstart + 1
  local suffix = string.format(' 󰁂 %d ', line_count)

  -- Try to get the native treesitter-highlighted fold text
  local ok, ts_foldtxt = pcall(vim.treesitter.foldtext)

  if ok and type(ts_foldtxt) == 'table' then
    -- Tree-sitter is active: append our suffix to the highlighted table
    table.insert(ts_foldtxt, { suffix, 'MoreMsg' })
    return ts_foldtxt
  else
    -- Fallback (indent/manual): Tree-sitter is not active or failed
    -- Get the plain text of the first line
    local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1] or ''
    return {
      { line, 'Normal' },
      { suffix, 'MoreMsg' },
    }
  end
end

-- Use the custom foldtext handler
vim.opt.foldtext = 'v:lua.my_foldtext()'
vim.opt.fillchars:append { fold = ' ' } -- Removes the "---" dots
vim.opt.foldcolumn = '0'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
