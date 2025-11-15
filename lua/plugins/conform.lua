-- Lightweight yet powerful formatter plugin for Neovim
--
-- https://github.com/stevearc/conform.nvim

-- Disable "format_on_save lsp_fallback" for languages that don't
-- have a well standardized coding style. You can add additional
-- languages here or re-enable it for the disabled ones.

local utils = require('utils')

-- list of directories to disable formatting for files under them (nested)
local ignore_dirs = {}

local lsp_fallback_disable_filetypes = { c = true, cpp = true }

-- List of file types to disable format-on-save on
local disable_filetypes = { python = true, jsonc = true, vue = true }

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      mode = '',
      desc = '[F]ormat buffer',
      function()
        require('conform').format({ timeout_ms = 500, lsp_format = 'fallback' })
      end,
    },
  },
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local filetype = vim.bo[bufnr].filetype

      -- Disable with a global or buffer-local variable
      if disable_filetypes[filetype] or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end

      -- Disable autoformat for files in a certain path
      local buf_name = vim.api.nvim_buf_get_name(bufnr) or ''
      if buf_name ~= '' and utils.is_path_under_dirs(buf_name, utils.merge_table_with_global_ignores(ignore_dirs)) then
        return
      end

      local lsp_format_opt = 'fallback'
      if lsp_fallback_disable_filetypes[filetype] then
        return -- https://github.com/nvim-lua/kickstart.nvim/commit/5e2d7e184b9d097c683792a8e5daed50a395cb0b
      end

      return {
        timeout_ms = 500,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
