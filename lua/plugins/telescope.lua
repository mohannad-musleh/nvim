-- telescope.nvim is a highly extendable fuzzy finder over lists.
--
-- https://github.com/nvim-telescope/telescope.nvim

-- NOTE: the `.` and `-` characters must be skipped with `%`
-- @see: https://github.com/nvim-telescope/telescope.nvim/issues/522#issuecomment-2085611980

local utils = require('utils')

local default_file_ignore_patterns = utils.str_table_to_patterns(utils.merge_table_with_global_ignores({}))

return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  -- branch = '0.1.x', -- NOTE: The current version (0.1.8) is missing preview horizontal scroll, so, for now, i will use the `master` branch
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable('make') == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
  },
  opts = {
    defaults = {
      mappings = {
        i = {
          ['<C-.>'] = 'preview_scrolling_right',
          ['<C-,>'] = 'preview_scrolling_left',
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        file_ignore_patterns = vim.tbl_deep_extend('force', default_file_ignore_patterns, {}),
      },
      live_grep = {
        file_ignore_patterns = vim.tbl_deep_extend('force', default_file_ignore_patterns, {}),
        additional_args = function(_)
          return { '--hidden' }
        end,
      },
    },
    extensions = {
      fzf = {},
      ['ui-select'] = {
        require('telescope.themes').get_dropdown({}),
      },
    },
  },
  config = function(_, opts)
    local telescope = require('telescope')
    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    telescope.setup(opts)

    local builtin = require('telescope.builtin')
    local action_state = require('telescope.actions.state')

    -- Enable Telescope extensions (if installed/available)
    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')
    pcall(telescope.load_extension, 'flutter') -- flutter-tools plugin

    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>sF', function()
      builtin.find_files({
        hidden = true,
        find_command = function()
          return { 'fd', '--type', 'f', '--color', 'never', '--no-ignore' }
        end,
      })
    end, { desc = '[S]earch [F]iles (including hidden files)' })
    vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Search Git Files' })
    vim.keymap.set('n', '<leader>stb', builtin.builtin, { desc = '[S]earch [T]elescope [B]uiltin' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>sls', builtin.lsp_document_symbols, { desc = '[S]earch [L]SP document [S]ymbols' })
    vim.keymap.set('n', '<leader>sp', function()
      builtin.find_files({
        cwd = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy'),
      })
    end, { desc = '[S]earch nvim [P]ackages' })
    vim.keymap.set('n', '<leader><leader>', function()
      builtin.buffers({
        initial_mode = 'normal',
        attach_mappings = function(prompt_bufnr, map)
          map('n', '<M-D>', function()
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:delete_selection(function(selection)
              vim.api.nvim_buf_delete(selection.bufnr, { force = true })
            end)
          end, { desc = 'delete_buffer! (Force delete)' })

          return true
        end,
      }, {
        sort_lastused = true,
        sort_mru = true,
        theme = 'dropdown',
      })
    end, { desc = 'Find existing buffers' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
