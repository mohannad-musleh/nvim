-- Neovim file explorer: edit your filesystem like a buffer
--
-- https://github.com/stevearc/oil.nvim

local detail = false

return {
  'stevearc/oil.nvim',
  ---@module "oil"
  ---@type oil.setupOpts
  opts = {
    -- Id is automatically added at the beginning, and name at the end
    -- See :help oil-columns
    columns = {},
    keymaps = {
      ['<C-h>'] = false,
      ['<C-j>'] = false,
      ['<C-k>'] = false,
      ['<C-l>'] = false,
      ['<space><space>'] = 'actions.refresh',
      ['<leader>sd'] = {
        function()
          require('telescope.builtin').find_files({
            cwd = require('oil').get_current_dir(),
          })
        end,
        mode = 'n',
        nowait = true,
        desc = '[S]earch current [D]irectory',
      },
      ['gd'] = {
        desc = '[G]et current urrent [D]irectory path and copy it to clipboard',
        callback = function()
          local cwd = require('oil').get_current_dir()
          vim.fn.setreg('+', cwd)
        end,
      },
      ['gfd'] = {
        desc = 'Toggle file detail view',
        callback = function()
          detail = not detail
          if detail then
            require('oil').set_columns({ 'permissions', 'size', 'mtime' })
          else
            require('oil').set_columns({})
          end
        end,
      },
    },
    -- Window-local options to use for oil buffers
    win_options = {
      list = true,
    },
    view_options = {
      show_hidden = true,
    },
  },
  config = function(_, opts)
    local oil = require('oil')
    oil.setup(opts)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'oil',
      group = vim.api.nvim_create_augroup('OilFileTypeMappings', { clear = true }),
      callback = function()
        vim.keymap.set('n', '<Esc>', require('oil').close, { buffer = 0, silent = true })
      end,
    })

    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
