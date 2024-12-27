-- Library of 40+ independent Lua modules improving overall Neovim (version 0.8 and higher) experience with minimal effort
--
-- https://github.com/echasnovski/mini.nvim

local root_patterns = { '.git', 'setup.py', 'pyproject.toml', '.mise.toml', '.mise.local.toml', 'package.json' }

--- Get the default session name for the path
---
--- NOTE: the path should be a root directory
---
---@param path string the root directory path to get its default session name
---@return string|nil
local function get_default_session_name_from_path(path)
  if path == nil or path == '' then
    return nil
  end

  return path:gsub('/', '%%'):gsub('%%$', '') .. '--default-session'
end

--- Check if there something shown in nvim or only an empty buffer
---
--- @see https://github.com/echasnovski/mini.nvim/blob/0bd6c4d25f2b0cc1ecb8b1a0f659cce54627e218/lua/mini/sessions.lua#L609-L610
local function is_something_shown()
  -- - Several buffers are listed (like session with placeholder buffers). That
  --   means unlisted buffers (like from `nvim-tree`) don't affect decision.
  local listed_buffers = vim.tbl_filter(function(buf_id)
    return vim.fn.buflisted(buf_id) == 1
  end, vim.api.nvim_list_bufs())
  if #listed_buffers > 1 then
    return true
  end

  -- - Current buffer is meant to show something else
  if vim.bo.filetype ~= '' then
    return true
  end

  -- - Current buffer has any lines (something opened explicitly).
  -- NOTE: Usage of `line2byte(line('$') + 1) < 0` seemed to be fine, but it
  -- doesn't work if some automated changed was made to buffer while leaving it
  -- empty (returns 2 instead of -1). This was also the reason of not being
  -- able to test with child Neovim process from 'tests/helpers'.
  local n_lines = vim.api.nvim_buf_line_count(0)
  if n_lines > 1 then
    return true
  end
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
  if string.len(first_line) > 0 then
    return true
  end

  return false
end

--- Try to find the root directory from the current working directory path
---
---@param cwd? string current working directory path, if missing, the value of `vim.fn.getcwd()` will be used
---@return string? # the matched root path or nil if not found
local function get_root_dir(cwd)
  cwd = cwd or vim.fn.getcwd()
  local matched_patterns = vim.fs.find(root_patterns, { upward = true, stop = vim.fs.dirname(cwd) })
  if matched_patterns == nil or #matched_patterns == 0 then
    return
  end

  local root_dir = vim.fs.dirname(matched_patterns[1])
  return root_dir
end

return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.extra').setup()

    -- Better Around/Inside textobjects
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-ai.md
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup({
      n_lines = 500,
      custom_textobjects = {
        B = MiniExtra.gen_ai_spec.buffer(),
        I = MiniExtra.gen_ai_spec.indent(),
        L = MiniExtra.gen_ai_spec.line(),
      },
    })

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- Session management
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-sessions.md
    local mini_sessions = require('mini.sessions')
    mini_sessions.setup({
      autoread = false,
      autowrite = true,
      directory = vim.fn.stdpath('data') .. '/sessions',
      file = '.mini.session.vim',
    });

    --- IIFE that register an autocommand to automatically create and read default session for the current project (if available)
    ---
    --- References:
    --- - https://github.com/echasnovski/mini.nvim/issues/890
    --- - https://github.com/echasnovski/mini.nvim/blob/0bd6c4d25f2b0cc1ecb8b1a0f659cce54627e218/lua/mini/sessions.lua#L609-L610
    (function()
      local augroup = vim.api.nvim_create_augroup('MiniSessionsCustomAutoCommands', {})

      local root_dir = get_root_dir()
      if root_dir == nil then
        return
      end

      local default_session_name = get_default_session_name_from_path(root_dir)

      vim.api.nvim_create_user_command('DefaultSessionName', function()
        print(default_session_name)
      end, { desc = 'Get current default session name' })

      if default_session_name == nil then
        return
      end

      vim.api.nvim_create_autocmd('VimEnter', {
        group = augroup,
        nested = true,
        once = true,
        callback = function()
          -- Don't autoread session if Neovim is opened to show something. That is
          -- when at least one of the following is true:
          -- - There are files in arguments (like `nvim foo.txt` with new file).
          -- - There something shown (a non-empty buffer is open)
          -- - A MiniSession is already loaded (this_session value is not empty string)
          if vim.fn.argc() > 0 or is_something_shown() then
            return
          end

          if
            vim.v.this_session == '' and vim.tbl_contains(vim.tbl_keys(MiniSessions.detected), default_session_name)
          then
            MiniSessions.read(default_session_name)
          end
        end,
      })
    end)()

    vim.keymap.set('n', '<leader>wd', "<cmd>lua MiniSessions.select('delete')<CR>", { desc = '[W]orkspace [D]elete' })
    vim.keymap.set('n', '<leader>wr', "<cmd>lua MiniSessions.select('read')<CR>", { desc = '[W]orkspace [R]ead' })
    vim.keymap.set('n', '<leader>wcd', function()
      if vim.v.this_session and vim.v.this_session ~= '' then
        vim.notify('Can not create default session while there is an active session', vim.log.levels.WARN)
        return
      end

      local root_dir = get_root_dir()
      if root_dir == nil then
        vim.notify('Failed to determine the project root directory', vim.log.levels.WARN)
        return
      end

      local default_session_name = get_default_session_name_from_path(root_dir)
      if default_session_name == nil then
        vim.notify('Failed to determine the default session name', vim.log.levels.WARN)
        return
      end

      if vim.tbl_contains(vim.tbl_keys(MiniSessions.detected), default_session_name) then
        vim.notify('default session already exists', vim.log.levels.WARN)
        return
      end

      MiniSessions.write(default_session_name, { force = false })
      vim.notify('Default session created successfully', vim.log.levels.WARN)
    end, { desc = '[W]orkspace [C]reate [D]efault' })

    vim.keymap.set('n', '<leader>ww', function()
      if vim.v.this_session and vim.v.this_session ~= '' then
        MiniSessions.write()
      else
        MiniSessions.select('write')
      end
    end, { desc = '[W]orkspace [W]rite' })

    vim.keymap.set('n', '<leader>wfd', function()
      MiniSessions.delete(nil, { force = true })
    end, { desc = '[W]orkspace [F]orce [D]elete' })

    -- Highlight patterns in text
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-hipatterns.md
    local hipatterns = require('mini.hipatterns')
    hipatterns.setup({
      highlighters = {
        -- Highlight hex color strings (`#rrggbb`) using that color (e.g. #0000ff)
        hex_color = hipatterns.gen_highlighter.hex_color({}),
      },
    })

    -- Move any selection in any direction
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-move.md
    require('mini.move').setup({
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = '<M-H>',
        right = '<M-L>',
        down = '<M-J>',
        up = '<M-K>',

        -- Move current line in Normal mode
        line_left = '<M-H>',
        line_right = '<M-L>',
        line_down = '<M-J>',
        line_up = '<M-K>',
      },
    })

    -- Visualize and work with indent scope
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-indentscope.md
    local indentscope = require('mini.indentscope')
    indentscope.setup({
      draw = {
        delay = 0,
        animation = indentscope.gen_animation.none(),
      },
      options = {
        indent_at_cursor = false,
      },
      -- Which character to use for drawing scope indicator
      symbol = '╎',
    })

    -- Pick anything
    --
    -- Built-in pickers:
    --
    --     Files.
    --     Pattern match (for fixed pattern or with live feedback; both allow file filtering via glob patterns).
    --     Buffers.
    --     Help tags.
    --     CLI output.
    --     Resume latest picker.
    --
    --
    -- This plugin has a CLI picker, which can be used to create a picker from a command result and get the picked value to do something with it.
    -- for example: `:lua vim.fn.setreg('+', MiniPick.builtin.cli({ command = { 'ls', '-lAh' } }))` will create picker
    --   from `ls` command and copy the picked item to clipboard
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md
    require('mini.pick').setup()

    -- Text edit operators
    --
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-operators.md
    require('mini.operators').setup({
      -- Each entry configures one operator.
      -- `prefix` defines keys mapped during `setup()`: in Normal mode
      -- to operate on textobject and line, in Visual - on selection.

      -- Evaluate text and replace with output
      evaluate = { prefix = '<leader>g=' },

      -- Exchange text regions
      exchange = {
        prefix = '<leader>gx',

        -- Whether to reindent new text to match previous indent
        reindent_linewise = true,
      },

      -- Multiply (duplicate) text
      multiply = { prefix = '<leader>gm' },

      -- Replace text with register
      replace = {
        prefix = '<leader>gr',

        -- Whether to reindent new text to match previous indent
        reindent_linewise = true,
      },

      -- Sort text
      sort = { prefix = '<leader>gs' },
    })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
