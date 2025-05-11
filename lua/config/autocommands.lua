--  See `:help lua-guide-autocommands`

local utils = require('utils')

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'help',
  group = vim.api.nvim_create_augroup('HelpMappings', { clear = true }),
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', ']q', ':cnext<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '[q', ':cprev<CR>', { noremap = true, silent = true })
  end,
})

local function is_big_file(bufnr)
  local current_buffer_path = vim.api.nvim_buf_get_name(bufnr)

  local file_stat = vim.uv.fs_stat(current_buffer_path)
  -- if file_stat then
  --   print(string.format('file_stat.size: %d (%.2f KB)', file_stat.size, file_stat.size / 1024))
  -- end
  if file_stat and (file_stat.size >= (1024 * 1024 * 2)) then -- 2MB
    -- print('file too large')
    return true
  end

  return false
end

vim.api.nvim_create_autocmd('BufReadPre', {
  pattern = { '*' },
  group = vim.api.nvim_create_augroup('bigfile-checker', { clear = true }),
  desc = 'Handle big files',
  callback = function(ev)
    ---@type number
    local bufnr = ev.buf
    local current_buffer_path = vim.api.nvim_buf_get_name(bufnr)

    local disable_diagnostics = false
    local disable_lsp = false
    local disable_opts = false
    local disable_treesitter = false

    if
      is_big_file(bufnr) and utils.is_path_under_dirs(current_buffer_path, utils.merge_table_with_global_ignores({}))
    then
      disable_diagnostics = true
      disable_lsp = true
      disable_opts = true
      disable_treesitter = true
    end

    if disable_treesitter then
      vim.b[bufnr].nvim_treesitter_disable_highlight = true
    end

    if disable_opts then
      vim.opt_local.swapfile = false
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.undolevels = -1
      vim.opt_local.undoreload = 0
      vim.opt_local.list = false
      vim.opt_local.spell = false
    end

    if disable_diagnostics then
      vim.diagnostic.enable(false, { bufnr = bufnr })
    end

    if disable_lsp then
      vim.api.nvim_create_autocmd({ 'LspAttach' }, {
        buffer = bufnr,
        ---@diagnostic disable-next-line: unused-local
        callback = function(event)
          local client_id = event.data.client_id

          vim.schedule(function()
            vim.defer_fn(function()
              if vim.lsp.buf_is_attached(bufnr, client_id) then
                vim.lsp.buf_detach_client(bufnr, client_id)
              end
            end, 100)
          end)
        end,
      })
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
