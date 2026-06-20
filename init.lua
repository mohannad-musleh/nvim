-- 1. Resolve the path to your pre-config file
local pre_config_path = vim.fs.root(0, { '.pre.nvim.lua' })
if pre_config_path then
  local full_path = pre_config_path .. '/.pre.nvim.lua'

  -- 2. Use Neovim's official security layer to read the file contents.
  -- This natively triggers the trusted/untrusted prompt and handles :trust.
  local file_content = vim.secure.read(full_path)

  if file_content and type(file_content) == 'string' then
    -- 3. Parse the file code into a function
    local loaded_chunk, load_err = loadstring(file_content, '@' .. full_path)

    if loaded_chunk then
      -- 4. Create a Sandbox Environment.
      -- By mapping standard global spaces to an empty table, we block functions,
      -- loops, requires, print statements, and OS execution entirely.
      local sandbox = {
        -- 1. Core namespaces
        vim = {
          g = vim.g,
          env = vim.env,
        },

        -- 2. Math Library (Exposes math.abs, math.floor, math.max, etc.)
        math = math,

        -- 3. String Library (Exposes string.find, string.match, string.sub, etc.)
        string = string,

        -- 4. Global Lua conversion functions (Safe and vital for string parsing)
        tonumber = tonumber,
        tostring = tostring,
        type = type,
      }

      -- Set the sandbox as the evaluation environment for the loaded file
      setfenv(loaded_chunk, sandbox)

      -- 5. Safe execute the project config file safely before init.lua continues
      local success, exec_err = pcall(loaded_chunk)
      if not success then vim.notify('Pre-config runtime error: ' .. tostring(exec_err), vim.log.levels.ERROR) end
    elseif load_err then
      vim.notify('Pre-config compilation error: ' .. tostring(load_err), vim.log.levels.ERROR)
    end
  elseif type(file_content) == 'boolean' and file_content == false then
    vim.g.disable_fe_plugins = true
    vim.g.additional_treesitter_parsers = nil
    vim.g.vue_lsp_location = nil
  end
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- this is a flag to disable folding related settings and setup when a plugin is used
-- currently the folding is managed by `nvim-ufo`. Hopefully I can replace it with native + treesitter setup
vim.g.enable_native_folding = false

-- Enable faster startup by caching compiled Lua modules
vim.loader.enable()

local utils = require 'utils'
local vim_pack_helpers = require 'helpers.vim_pack'
local workspace_helpers = require 'helpers.workspace'
local gh = vim_pack_helpers.gh

require('vim._core.ui2').enable {}

require 'config'

local treesitter_installed = false

local treesitter_parsers = {
  'bash',
  'c',
  'diff',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'regex',
  'json',
  'http',
}

if type(vim.g.additional_treesitter_parsers) == 'table' then vim.list_extend(treesitter_parsers, vim.g.additional_treesitter_parsers) end

-- ============================================================
-- PLUGINS
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })

  vim.api.nvim_create_user_command(
    'VimPackList',
    function() vim.pack.update(nil, { offline = true }) end,
    { nargs = 0, desc = 'List installed packages using vim.pack' }
  )

  vim.api.nvim_create_user_command('VimPackUpdate', function() vim.pack.update() end, { nargs = 0, desc = 'Update installed packages using vim.pack' })

  do -- NeoVIM builtin plugins
    vim.schedule(function()
      -- To open a visual and interactive undo tree, type :Undotree
      -- See `:help :Undotree`
      vim.cmd.packadd 'nvim.undotree'
      vim.keymap.set('n', '<leader>u', vim.cmd.Undotree, { desc = 'Toggle built-in Undotree' })
    end)

    -- vim.cmd.packadd('nvim.difftool')
  end

  do -- [[ Colorscheme ]]
    vim.pack.add { gh 'rebelot/kanagawa.nvim' }

    require('kanagawa').setup {
      compile = false, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = false },
      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      -- colors = { -- add/modify theme and palette colors
      --   palette = {},
      --   theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      -- },
      ---@diagnostic disable-next-line: unused-local
      overrides = function(colors) -- add/modify highlights
        return {
          ['@markup.link.url.markdown_inline'] = { link = 'Special' }, -- (url)
          ['@markup.link.label.markdown_inline'] = { link = 'WarningMsg' }, -- [label]
          ['@markup.italic.markdown_inline'] = { link = 'Exception' }, -- *italic*
          ['@markup.raw.markdown_inline'] = { link = 'String' }, -- `code`
          ['@markup.list.markdown'] = { link = 'Function' }, -- + list
          ['@markup.quote.markdown'] = { link = 'Error' }, -- > blockcode
          ['@markup.list.checked.markdown'] = { link = 'WarningMsg' }, -- - [X] checked list item
        }
      end,
      theme = 'dragon', -- Load "wave" theme when 'background' option is not set
      background = { -- map the value of 'background' option to a theme
        dark = 'dragon', -- try "dragon" !
      },
    }

    vim.cmd.colorscheme 'kanagawa'
  end

  do -- snacks.nvim
    --  A collection of QoL plugins for Neovim
    --
    --  https://github.com/folke/snacks.nvim
    --  WARNING: folke/snacks.nvim expect to be loaded before `VimEnter` event
    vim.pack.add { gh 'folke/snacks.nvim' }

    -- disable all animations globally
    vim.g.snacks_animate = false

    ---@type snacks.Config
    require('snacks').setup {
      bigfile = {
        enabled = true,
        notify = true, -- show notification when big file detected
        size = 1.5 * 1024 * 1024, -- 1.5MB
        line_length = 1000, -- average line length (useful for minified files)
      },
      dashboard = { enabled = false },
      explorer = {
        replace_netrw = false,
        trash = false,
      },
      image = {
        enabled = false,
      },
      indent = {
        enabled = true,
        only_scope = true,
        only_current = true,
        scope = {
          enabled = true,
          char = '╎',
        },
        animate = {
          enabled = false,
        },
        indent = {
          enabled = true,
          char = ' ',
          only_scope = true,
          only_current = true,
          scope = {
            enabled = true,
            char = '╎',
          },
          animate = {
            enabled = false,
          },
        },
      },
      input = {
        enabled = true,
      },
      notifier = {
        enabled = true,
        top_down = false,
        -- style = 'minimal', -- Options: "compact", "minimal", "fancy", or "default"
      },
      picker = {
        sources = {
          projects = {
            recent = false,
            patterns = { '.git', 'pyproject.toml', 'build.zig.zon', 'go.mod', 'package.json' },
          },
          lines = {
            layout = {
              preset = 'telescope',
              ---@diagnostic disable-next-line: assign-type-mismatch
              preview = true,
            },
          },
          explorer = {
            icons = {
              git = { enabled = false },
              files = { enabled = false },
            },
            focus = 'list',
            diagnostics = false,
            git_status = false,
            -- layout = {
            --   preset = function() return vim.o.columns >= 120 and 'default' or 'vertical' end,
            --   ---@diagnostic disable-next-line: assign-type-mismatch
            --   preview = false,
            -- },
            layout = {
              layout = {
                position = 'right',
              },
            },
            tree = true,
            auto_close = false,
            preview = function(ctx)
              -- Get the filename from the current item
              local item = ctx.item
              if item and item.file and item.file:match '%.env$' then
                -- disable preview for `.env` file
                ctx.preview:reset()
                ctx.preview:notify('preview is disabled for this file', 'warn')
                return false
              end

              -- Fallback to default file preview for everything else
              return Snacks.picker.preview.file(ctx)
            end,
            win = {
              list = {
                keys = {
                  ['<C-v>'] = 'edit_vsplit', -- Vertical split
                  ['<C-s>'] = 'edit_split', -- Horizontal split
                },
              },
            },
          },
        },
      },
      quickfile = {},
      scope = {
        enabled = true,
      },
      scratch = { -- doc: https://github.com/folke/snacks.nvim/blob/main/docs/scratch.md
        root = vim.fs.joinpath(vim.fn.stdpath 'data', 'scratch'),
        filekey = {
          id = nil, ---@type string? unique id used instead of name for the filename hash
          cwd = true, -- use current working directory
          branch = false, -- use current branch name
          count = true, -- use vim.v.count1
        },
        ft = function()
          if vim.bo.buftype == '' and vim.bo.filetype ~= '' then return vim.bo.filetype end
          return 'markdown'
        end,
      },
      statuscolumn = {
        left = { 'mark', 'sign' }, -- priority of signs on the left (high to low)
        right = { 'git' }, -- priority of signs on the right (high to low)
        folds = {
          open = false, -- show open fold icons
          git_hl = false, -- use Git Signs hl for fold icons
        },
      },
      styles = {
        terminal = {
          keys = {
            term_normal = { '<C-t>q', [[<C-\><C-n>]], mode = 't', desc = 'Terminal Normal Mode' },
          },
        },
      },
      terminal = {
        interactive = true,
        auto_close = true,
      },
      toggle = {},
      -- words = {},
      zen = {
        zoom = {
          show = {},
        },
      },
    }

    -- doc: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#general
    local snacks_keymaps = {
      -- Pickers
      { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp Pages' },
      ---@diagnostic disable-next-line: assign-type-mismatch
      { '<leader>sk', function() Snacks.picker.keymaps { layout = { preview = false } } end, desc = '[S]earch [K]eymaps' },
      { '<leader>sf', function() Snacks.picker.files { hidden = true } end, desc = '[S]earch [F]iles' },
      { '<leader>sF', function() Snacks.picker.files { hidden = true, ignored = true } end, desc = '[S]earch [F]iles (including ignored ones)' },
      { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
      { '<leader>ss', function() Snacks.picker.pickers() end, desc = '[S]earch [S]elect a Picker' },
      { '<leader>sg', function() Snacks.picker.grep { hidden = true } end, desc = '[S]earch by [G]rep' },
      { '<leader>sG', function() Snacks.picker.grep_buffers() end, desc = '[S]earch by [G]rep Open Buffers' },
      { '<leader>sp', function() Snacks.picker.git_grep { untracked = true, submodules = true } end, desc = '[S]earch project files ([G]it based)' },
      { '<leader>sw', function() Snacks.picker.grep_word { hidden = true } end, desc = '[S]earch [W]ord', mode = { 'n', 'x' } },
      { '<leader>sM', function() Snacks.picker.man() end, desc = 'Man Pages' },
      { '<leader>sd', function() Snacks.picker.diagnostics_buffer() end, desc = '[S]earch [D]iagnostics (current buffer)' },
      { '<leader>sD', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
      { '<leader>si', function() Snacks.picker.icons() end, desc = '[S]earch [I]cons (emojis)' },
      { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
      { '<leader>sP', function() Snacks.picker.projects() end, desc = '[S]earch [P]rojects' },
      { '<leader>/', function() Snacks.picker.lines() end, desc = 'Search Current Buffer Lines' },
      { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
      { '<leader>-', function() Snacks.explorer() end, desc = 'File Explorer' },
      { '<leader><leader>', function() Snacks.picker.buffers() end, desc = 'Find exisiting Buffers' },

      -- Zen
      { '<leader>zz', function() Snacks.zen.zoom() end, desc = '[Z]en [Z]oom' },

      -- Scratch
      {
        '<leader>.',
        function() require('snacks').scratch { name = 'Project Notes', ft = 'markdown', filekey = { cwd = true, branch = false } } end,
        desc = 'Project Scratch Notes',
      },
      {
        '<leader>ng',
        function() require('snacks').scratch { name = 'Global Notes', ft = 'markdown', filekey = { cwd = false, branch = false } } end,
        desc = 'Global Scratch Notes',
      },
      { '<leader>sS', function() Snacks.picker.scratch() end, desc = '[S]earch [S]cratch' },

      -- Terminal
      { '<leader>tf', function() Snacks.terminal.toggle(nil, { win = { position = 'float' } }) end, desc = '[T]erminal in [F]loating Window' },

      -- todo-comments plugin pickers
      {
        '<leader>sT',
        function()
          ---@diagnostic disable-next-line: undefined-field
          if Snacks.picker['todo_comments'] ~= nil then Snacks.picker.todo_comments() end
        end,
        desc = '[S]earch [T]odo Comments',
      },
      {
        '<leader>st',
        function()
          ---@diagnostic disable-next-line: undefined-field
          if Snacks.picker['todo_comments'] ~= nil then Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } } end
        end,
        desc = '[S]earch [T]odo Comments (TODO|FIX|FIXME only)',
      },
    }

    for _, keymap in pairs(snacks_keymaps) do
      Snacks.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap)
    end

    do -- OpenTerminal command
      vim.api.nvim_create_user_command('OpenTerminal', function(opts)
        local params = {}

        for _, arg in ipairs(opts.fargs) do
          local key, val = arg:match '([^=]+)=([^=]+)'
          if key and val then params[key] = val end
        end

        local function to_bool(val)
          if val == 'true' then return true end
          if val == 'false' then return false end
          return nil
        end

        local cmd = params['cmd']
        local position = params['position']
        local start_insert = to_bool(params['start_insert'])
        local auto_insert = to_bool(params['auto_insert'])
        local auto_close = to_bool(params['auto_close'])

        ---@type snacks.terminal.Opts
        local terminal_opts = {
          start_insert = true,
          auto_insert = false,
          auto_close = true,
        }

        if start_insert ~= nil then terminal_opts.start_insert = start_insert end
        if auto_close ~= nil then terminal_opts.auto_close = auto_close end
        if auto_insert ~= nil then terminal_opts.auto_insert = auto_insert end

        if position ~= nil then terminal_opts.win = { position = position } end

        Snacks.terminal.toggle(cmd, terminal_opts)
      end, {
        nargs = '*',
        ---@diagnostic disable-next-line: unused-local
        complete = function(ArgLead, CmdLine, CursorPos)
          local options = {
            cmd = {},
            position = { 'float', 'bottom', 'top', 'left', 'right' },
            start_insert = { 'true', 'false' },
            auto_close = { 'true', 'false' },
            auto_insert = { 'true', 'false' },
          }

          if ArgLead:find '=' then
            local key, prefix = ArgLead:match '([^=]+)=(.*)'
            if options[key] then
              local suggestions = {}
              for _, v in ipairs(options[key]) do
                if v:sub(1, #prefix) == prefix then table.insert(suggestions, key .. '=' .. v) end
              end
              return suggestions
            end
          end

          local suggestions = {}
          for key, _ in pairs(options) do
            if (key .. '='):sub(1, #ArgLead) == ArgLead then table.insert(suggestions, key .. '=') end
          end
          return suggestions
        end,

        desc = "Args: cmd=btop (default: nil) position=float|bottom|top|left|right (default: <snacks's default>) start_insert=true|false (default: true) auto_close=true|false (default: true) auto_insert=true|false (default: false)",
      })
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('snacks-picker-lsp-attach', { clear = true }),
      callback = function(event)
        local buf = event.buf

        -- Find references for the word under your cursor.
        vim.keymap.set('n', 'grr', Snacks.picker.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

        -- Jump to the implementation of the word under your cursor.
        -- Useful when your language has ways of declaring types without an actual implementation.
        vim.keymap.set('n', 'gri', Snacks.picker.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

        -- Jump to the definition of the word under your cursor.
        -- This is where a variable was first declared, or where a function is defined, etc.
        -- To jump back, press <C-t>.
        vim.keymap.set('n', 'grd', Snacks.picker.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

        -- Jump to the type of the word under your cursor.
        -- Useful when you're not sure what type a variable is and you want to see
        -- the definition of its *type*, not where it was *defined*.
        vim.keymap.set('n', 'grt', Snacks.picker.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
      end,
    })

    if Snacks.config['notifier'] ~= nil and Snacks.config['notifier']['enabled'] then
      -- Snacks notifier -- Advanced LSP Progress
      ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
      local progress = vim.defaulttable()
      vim.api.nvim_create_autocmd('LspProgress', {
        ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
          if not client or type(value) ~= 'table' then return end
          local p = progress[client.id]

          for i = 1, #p + 1 do
            if i == #p + 1 or p[i].token == ev.data.params.token then
              p[i] = {
                token = ev.data.params.token,
                msg = ('[%3d%%] %s%s'):format(
                  value.kind == 'end' and 100 or value.percentage or 100,
                  value.title or '',
                  value.message and (' **%s**'):format(value.message) or ''
                ),
                done = value.kind == 'end',
              }
              break
            end
          end

          local msg = {} ---@type string[]
          progress[client.id] = vim.tbl_filter(function(v) return table.insert(msg, v.msg) or not v.done end, p)

          local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
          vim.notify(table.concat(msg, '\n'), 'info', {
            id = 'lsp_progress',
            title = client.name,
            opts = function(notif) notif.icon = #progress[client.id] == 0 and ' ' or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1] end,
          })
        end,
      })
    end
  end

  do -- oil.nvim
    --- Neovim file explorer: edit your filesystem like a buffer
    ---
    --- https://github.com/stevearc/oil.nvim
    vim.pack.add { gh 'stevearc/oil.nvim' }

    require('oil').setup {
      -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
      -- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
      default_file_explorer = false,
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
          function() Snacks.picker.files { cwd = require('oil').get_current_dir() } end,
          mode = 'n',
          nowait = true,
          desc = '[S]earch current [D]irectory',
        },
        ['gd'] = {
          desc = '[G]et current [D]irectory path and copy it to clipboard',
          callback = function()
            local cwd = require('oil').get_current_dir()
            vim.fn.setreg('+', cwd)
            vim.notify('Current directory path copied to clipboard', 'info')
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
    }

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'oil',
      group = vim.api.nvim_create_augroup('OilFileTypeMappings', { clear = true }),
      callback = function() vim.keymap.set('n', '<Esc>', require('oil').close, { buffer = 0, silent = true }) end,
    })

    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
  end

  do -- guess-indent
    -- `guess-indent.nvim` - a plugin for automatically detecting and setting the indentation.
    --
    -- https://github.com/NMAC427/guess-indent.nvim
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      once = true,
      callback = function()
        vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
        require('guess-indent').setup {}
      end,
    })
  end

  do -- Gitsigns
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    --
    -- https://github.com/lewis6991/gitsigns.nvim
    vim.schedule(function()
      vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
      require('gitsigns').setup {
        signs = {
          add = { text = '+' }, ---@diagnostic disable-line: missing-fields
          change = { text = '~' }, ---@diagnostic disable-line: missing-fields
          delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
          topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
          changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
        },
      }
    end)
  end

  do -- Neogit
    -- An interactive and powerful Git interface for Neovim
    --
    -- https://github.com/NeogitOrg/neogit
    --
    -- diffview: https://github.com/sindrets/diffview.nvim
    vim.schedule(function()
      vim.pack.add {
        { src = gh 'NeogitOrg/neogit' },
        { src = gh 'sindrets/diffview.nvim' },
      }

      require('neogit').setup {
        kind = 'vsplit',
      }

      -- Also setup diffview if it was installed as a dependency
      require('diffview').setup {}
    end)
  end

  do -- todo-comments
    -- Highlight todo, notes, etc in comments
    local todo_comments_setup = utils.once(function()
      vim.pack.add { gh 'folke/todo-comments.nvim' }
      require('todo-comments').setup { signs = false }
    end)

    vim.api.nvim_create_autocmd({ 'BufNewFile' }, { once = true, callback = function() todo_comments_setup() end })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function(args)
        if not utils.is_valid_file_path(vim.fn.expand '%:p') then return end

        -- like once = true, but lazy one (to be able to run a condition check first)
        vim.api.nvim_del_autocmd(args.id)

        todo_comments_setup()
      end,
    })
  end

  do -- mini.nvim
    -- Library of 40+ independent Lua modules improving overall Neovim (version 0.8 and higher) experience with minimal effort
    --
    -- https://github.com/nvim-mini/mini.nvim
    vim.pack.add { gh 'nvim-mini/mini.nvim' }
    require('mini.extra').setup()

    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup {
      -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
      mappings = {
        around_next = 'aa',
        inside_next = 'ii',
      },
      n_lines = 500,
      custom_textobjects = {
        B = MiniExtra.gen_ai_spec.buffer(),
        I = MiniExtra.gen_ai_spec.indent(),
        L = MiniExtra.gen_ai_spec.line(),
      },
    }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- Highlight patterns in text
    --
    -- https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-hipatterns.md
    local hipatterns = require 'mini.hipatterns'
    hipatterns.setup {
      highlighters = {
        -- Highlight hex color strings (`#rrggbb`) using that color (e.g. #0000ff)
        hex_color = hipatterns.gen_highlighter.hex_color {},
      },
    }

    -- Move any selection in any direction
    --
    -- https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-move.md
    require('mini.move').setup {
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
    }
  end

  do -- [[ LSP Configuration ]]
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    -- Useful status updates for LSP.
    -- vim.pack.add { gh 'j-hui/fidget.nvim' }
    -- require('fidget').setup {}

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('aug-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('aug-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('aug-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'aug-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          map('<leader>TIH', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle [I]nlay [H]ints')
        end
      end,
    })

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --  See `:help lsp-config` for information about keys and how to configure
    ---@type table<string, vim.lsp.Config>
    local servers = {
      -- clangd = {},
      -- gopls = {},
      -- pyright = {},
      -- rust_analyzer = {},
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`ts_ls`) will work just fine
      -- ts_ls = {},

      stylua = {}, -- Used to format Lua code

      -- Special Lua Config, as recommended by neovim help docs
      lua_ls = {
        on_init = function(client)
          client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
          end

          ---@diagnostic disable-next-line: param-type-mismatch
          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua or {}, {
            runtime = {
              version = 'LuaJIT',
              path = { 'lua/?.lua', 'lua/?/init.lua' },
            },
            workspace = {
              checkThirdParty = false,
              -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
              --  See https://github.com/neovim/nvim-lspconfig/issues/3189
              library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                '${3rd}/luv/library',
                '${3rd}/busted/library',
              }),
            },
          })
        end,
        ---@type lspconfig.settings.lua_ls
        settings = {
          Lua = {
            format = { enable = false }, -- Disable formatting (formatting is done by stylua)
          },
        },
      },
    }

    if utils.executable 'gopls' then
      servers['gopls'] = {}
      table.insert(treesitter_parsers, 'go')
    end

    if utils.executable 'zls' then
      servers['zls'] = {}
      table.insert(treesitter_parsers, 'zig')
    end

    if utils.executable 'docker' then
      if utils.executable 'npm' then
        servers['dockerls'] = {}
        servers['docker_compose_language_service'] = {}
      end

      table.insert(treesitter_parsers, 'dockerfile')
    end

    if utils.executable 'python' then
      -- WARNING: This assumes the correct ruff you want to use is available in `PATH`, which can be done by installing
      -- `ruff` globally, or enable the current virtualenv. For me, `mise` do that automatically (using `MISE_PYTHON_UV_VENV_AUTO`)
      if utils.executable 'ruff' then
        servers['ruff'] = {}
        servers['pyright'] = {
          settings = {
            pyright = {
              disableOrganizeImports = true,
            },
          },
        }
      else
        servers['pyright'] = {}
      end
    end

    if utils.executable 'npm' and workspace_helpers.is_fe_project() and not vim.g.disable_fe_plugins then
      local vtsls_config = {}

      vim.list_extend(treesitter_parsers, {
        'html',
        'css',
        'javascript',
        'typescript',
        'jsdoc',
      })

      if workspace_helpers.is_fe_project { 'vue' } then
        table.insert(treesitter_parsers, 'vue')

        local is_custom_vue_lsp_location = false
        local vue_language_server_path =
          vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'vue-language-server', 'node_modules', '@vue/language-server')

        if type(vim.g.vue_lsp_location) == 'string' and vim.g.vue_lsp_location ~= '' then
          vue_language_server_path = vim.g.vue_lsp_location
          is_custom_vue_lsp_location = true
        end

        -- For vue setup, install the LSP manually.
        -- cmd: nvim --headless -c 'packloadall' -c 'MasonInstall vue-language-server' -c qall
        if vim.fn.isdirectory(vue_language_server_path) == 1 then
          local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }
          local vue_plugin = {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          }
          vtsls_config = {
            settings = {
              vtsls = {
                tsserver = {
                  globalPlugins = {
                    vue_plugin,
                  },
                },
              },
            },
            filetypes = tsserver_filetypes,
          }
        elseif is_custom_vue_lsp_location then
          vim.notify('Vue LSP is not available at `' .. vue_language_server_path .. '`', 'warn', {})
        end
      end

      servers = vim.tbl_extend('force', servers, {
        html = {},
        cssls = {},
        emmet_language_server = {
          filetypes = {
            'css',
            'html',
            'javascript',
            'javascriptreact',
            'scss',
            'pug',
            'typescriptreact',
            'vue',
          },
        },
        -- tailwindcss = {
        --   classAttributes = { 'class', ':class', 'v-bind:class', 'className', 'class:list', 'classList', 'ngClass' },
        --   includeLanguages = {
        --     htmlangular = 'html',
        --     templ = 'html',
        --   },
        --   lint = {
        --     cssConflict = 'warning',
        --     invalidApply = 'error',
        --     invalidConfigPath = 'error',
        --     invalidScreen = 'error',
        --     invalidTailwindDirective = 'error',
        --     invalidVariant = 'error',
        --     recommendedVariantOrder = 'warning',
        --   },
        --   validate = true,
        -- },
        vtsls = vtsls_config,
        -- vue_ls = {},
      })
    end

    if utils.executable 'npm' then -- json lsp + json schemas support
      vim.pack.add {
        gh 'b0o/SchemaStore.nvim',
      }

      servers['jsonls'] = {
        init_options = {
          provideFormatter = false,
        },
        on_new_config = function(new_config)
          -- lazy load schemastore
          new_config.settings.json.schemas = new_config.settings.json.schemas or {}
          vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
        end,
      }
    end

    vim.pack.add {
      gh 'neovim/nvim-lspconfig',
      gh 'mason-org/mason.nvim',
      gh 'mason-org/mason-lspconfig.nvim',
      gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
    }

    -- Automatically install LSPs and related tools to stdpath for Neovim
    require('mason').setup {}

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in that menu.

    -- list of LSP server names to not be installed using Mason (installed manually)
    local manually_installed_lsps = {
      'mypy',
      'ruff',
      'biome',
      'zls',
      'gopls',
    }

    local ensure_installed = vim.tbl_filter(
      function(l) return not vim.tbl_contains(manually_installed_lsps, l) end,
      vim.list_extend(vim.tbl_keys(servers or {}), {
        -- You can add other tools here that you want Mason to install
      })
    )

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for name, server in pairs(servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end

  do -- nvim-link
    -- An asynchronous linter plugin for Neovim complementary to the built-in Language Server Protocol support.
    --
    -- https://github.com/mfussenegger/nvim-lint

    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      once = true,
      callback = function()
        vim.pack.add { gh 'mfussenegger/nvim-lint' }

        local lint = require 'lint'
        lint.linters_by_ft = {
          markdown = {},
          python = {},
        }

        if utils.executable 'ruff' then lint.linters_by_ft.python = { 'ruff' } end

        -- Create autocommand which carries out the actual linting
        -- on the specified events.
        local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
          group = lint_augroup,
          callback = function()
            -- Only run the linter in buffers that you can modify in order to
            -- avoid superfluous noise, notably within the handy LSP pop-ups that
            -- describe the hovered symbol using Markdown.
            if vim.bo.modifiable then lint.try_lint() end
          end,
        })
      end,
    })
  end

  do -- conform -- code formatter
    -- Lightweight yet powerful formatter plugin for Neovim
    --
    -- https://github.com/stevearc/conform.nvim

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      once = true,
      callback = function()
        vim.pack.add { gh 'stevearc/conform.nvim' }
        require('conform').setup {
          notify_on_error = false,
          format_on_save = function(bufnr)
            -- You can specify filetypes to autoformat on save here:
            local enabled_filetypes = {
              -- lua = true,
              -- python = true,
            }
            if enabled_filetypes[vim.bo[bufnr].filetype] then
              return { timeout_ms = 500 }
            else
              return nil
            end
          end,
          default_format_opts = {
            lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
          },
          -- You can also specify external formatters in here.
          formatters_by_ft = {
            -- rust = { 'rustfmt' },
            -- Conform can also run multiple formatters sequentially
            -- python = { "isort", "black" },
            --
            -- You can use 'stop_after_first' to run the first available formatter from the list
            -- javascript = { "prettierd", "prettier", stop_after_first = true },
          },
        }

        vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
      end,
    })
  end

  do -- [[ Autocomplete Engine ]]
    vim.api.nvim_create_autocmd('InsertEnter', {
      once = true,
      callback = function()
        -- Performant, batteries-included completion plugin for Neovim
        --
        -- https://github.com/saghen/blink.cmp
        vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
        require('blink.cmp').setup {
          keymap = {
            -- 'default' (recommended) for mappings similar to built-in completions
            --   <c-y> to accept ([y]es) the completion.
            --    This will auto-import if your LSP supports it.
            --    This will expand snippets if the LSP sent a snippet.
            -- 'super-tab' for tab to accept
            -- 'enter' for enter to accept
            -- 'none' for no mappings
            --
            -- For an understanding of why the 'default' preset is recommended,
            -- you will need to read `:help ins-completion`
            --
            -- All presets have the following mappings:
            -- <tab>/<s-tab>: move to right/left of your snippet expansion
            -- <c-space>: Open menu or open docs if already open
            -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
            -- <c-e>: Hide menu
            -- <c-k>: Toggle signature help
            --
            -- See `:help blink-cmp-config-keymap` for defining your own keymap
            preset = 'default',
          },

          appearance = {
            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = 'normal',
          },
          --
          -- See `:help blink-cmp-config-fuzzy` for more information
          fuzzy = { implementation = 'lua' },

          -- Shows a signature help window while you type arguments for a function
          signature = { enabled = true },
        }
      end,
    })
  end

  do -- nvim-treesitter
    --  Used to highlight, edit, and navigate code
    --
    --  See `:help nvim-treesitter-intro`
    vim.pack.add {
      { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
      { src = gh 'nvim-treesitter/nvim-treesitter-context' },
    }

    treesitter_installed = true

    require('treesitter-context').setup { max_lines = 10, line_numbers = false }

    ---@param buf integer
    ---@param language string
    local function treesitter_try_attach(buf, language)
      -- Check if a parser exists and load it
      if not vim.treesitter.language.add(language) then return end
      -- Enable syntax highlighting and other treesitter features
      vim.treesitter.start(buf, language)

      if not vim.g.enable_native_folding then return end

      -- Enable treesitter based folds
      -- For more info on folds see `:help folds`
      -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo.foldmethod = 'indent'
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99

      -- Check if treesitter indentation is available for this language, and if so enable it
      -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
      local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

      -- Enable treesitter based indentation
      -- WARNING: this does not work with zig and python (maybe others too), will use nvim-ufo for now
      if has_indent_query and vim.tbl_contains({ 'lua', 'zig' }, language) then
        vim.wo.foldmethod = 'expr'
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local buf, filetype = args.buf, args.match

        local language = vim.treesitter.language.get_lang(filetype)
        if not language then return end

        local installed_parsers = require('nvim-treesitter').get_installed 'parsers'
        local available_parsers = require('nvim-treesitter').get_available()

        if vim.tbl_contains(installed_parsers, language) then
          -- Enable the parser if it is already installed
          treesitter_try_attach(buf, language)
        elseif vim.tbl_contains(available_parsers, language) then
          -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
          require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
        else
          -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
          treesitter_try_attach(buf, language)
        end
      end,
    })
  end

  do -- flash
    -- Navigate your code with search labels, enhanced character motions and Treesitter integration.
    --
    -- https://github.com/folke/flash.nvim

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      once = true,
      callback = function()
        vim.pack.add {
          { src = gh 'folke/flash.nvim' },
        }

        local flash = require 'flash'

        flash.setup {}

        vim.keymap.set({ 'n', 'x', 'o' }, 's', function() flash.jump() end, { desc = 'Flash' })
        vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() flash.treesitter() end, { desc = 'Flash Treesitter' })
        vim.keymap.set('o', 'r', function() flash.remote() end, { desc = 'Remote Flash' })
        vim.keymap.set({ 'x', 'o' }, 'R', function() flash.treesitter_search() end, { desc = 'Treesitter Search' })
      end,
    })
  end

  if not vim.g.enable_native_folding then -- nvim-ufo
    -- Not UFO in the sky, but an ultra fold in Neovim.
    --
    -- https://github.com/kevinhwang91/nvim-ufo

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      once = true,
      callback = function()
        vim.pack.add {
          { src = gh 'kevinhwang91/nvim-ufo' },
          { src = gh 'kevinhwang91/promise-async' },
        }

        vim.opt.foldcolumn = '0'
        vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true

        require('ufo').setup {
          fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
            local newVirtText = {}
            local suffix = (' 󰁂 %d '):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
              local chunkText = chunk[1]
              local chunkWidth = vim.fn.strdisplaywidth(chunkText)
              if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
              else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, { chunkText, hlGroup })
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                -- str width returned from truncate() may less than 2nd argument, need padding
                if curWidth + chunkWidth < targetWidth then suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth) end
                break
              end
              curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, { suffix, 'MoreMsg' })
            return newVirtText
          end,
          ---@diagnostic disable-next-line: unused-local
          provider_selector = function(bufnr, filetype, buftype)
            if filetype == 'vue' then return { 'lsp', 'treesitter' } end

            return { 'lsp', 'indent' }
          end,
        }
      end,
    })
  end

  do -- cloak
    -- Cloak allows you to overlay *'s over defined patterns in defined files.
    --
    -- https://github.com/laytan/cloak.nvim

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'env',
      once = true,
      callback = function()
        vim.pack.add {
          { src = gh 'laytan/cloak.nvim' },
        }

        require('cloak').setup {
          enabled = true,
          cloak_length = 4,
          cloak_character = '*',
          -- True to cloak Telescope preview buffers.
          cloak_telescope = true,
          -- Re-enable cloak when a matched buffer leaves the window.
          cloak_on_leave = true,
          -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
          highlight_group = 'Comment',
          patterns = {
            {
              file_pattern = {
                -- WARNING: this is not a perfect regex, but it works for now.
                '.env{,.*[^example]}',
                -- '.env*',
                'wrangler.toml',
                '.dev.vars',
              },
              cloak_pattern = { '=.+', ':.+' },
            },
          },
        }
      end,
    })
  end

  do -- Trouble.nvim
    -- A pretty diagnostics, references, telescope results, quickfix and location list
    -- to help you solve all the trouble your code is causing.
    --
    -- https://github.com/folke/trouble.nvim

    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      once = true,
      callback = function()
        vim.pack.add {
          { src = gh 'folke/trouble.nvim' },
        }

        require('trouble').setup {
          focus = false,
          open_no_results = true,
          max_items = false,
          win = {
            type = 'split',
            position = 'right',
          },
        }

        local function map(mode, l, r, opts)
          opts = opts or {}
          vim.keymap.set(mode, l, r, opts)
        end

        local keys = {
          -- Example:
          -- {
          --   l = '<leader>xL',
          --   r = '<cmd>Trouble loclist toggle<cr>',
          --   desc = 'Location List (Trouble)',
          -- },
        }

        for _, keymap in pairs(keys) do
          map('n', keymap.l, keymap.r, { desc = keymap.desc })
        end
      end,
    })
  end

  do -- render-markdown
    -- Plugin to improve viewing Markdown files in Neovim
    --
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      once = true,
      callback = function()
        vim.pack.add {
          { src = gh 'MeanderingProgrammer/render-markdown.nvim' },
          { src = gh 'nvim-treesitter/nvim-treesitter' },
        }

        local rmd = require 'render-markdown'
        rmd.setup {
          -- Whether markdown should be rendered by default.
          enabled = false,
          latex = { enabled = false },
        }
        rmd.disable()
      end,
    })
  end

  do -- http client
    -- Easy to use HTTP client plugin for neovim. Same syntax as IntelliJ HTTP client
    --
    -- https://github.com/heilgar/nvim-http-client

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'http', 'rest' },
      once = true,
      callback = function(ev)
        vim.pack.add {
          { src = gh 'heilgar/nvim-http-client' },
          { src = gh 'nvim-lua/plenary.nvim' },
        }

        require('http_client').setup {
          default_env_file = '.env.json',
          request_timeout = 30000,
          split_direction = 'right',
          create_keybindings = false,
          user_agent = 'heilgar/nvim-http-client', -- Custom User-Agent header

          -- Profiling (timing metrics for requests)
          profiling = {
            enabled = true,
            show_in_response = true,
            detailed_metrics = true,
          },
        }

        local keymaps = {
          { '<leader>he', '<cmd>HttpEnvFile<cr>', desc = 'Select HTTP environment file' },
          { '<leader>hs', '<cmd>HttpSaveResponse<cr>', desc = 'Save HttpResponse to file' },
          { '<leader>hr', '<cmd>HttpRun<cr>', desc = 'Run HTTP request' },
          { '<leader>hx', '<cmd>HttpStop<cr>', desc = 'Stop HTTP request' },
          { '<leader>hd', '<cmd>HttpDryRun<cr>', desc = 'DryRun HTTP request' },
          { '<leader>hv', '<cmd>HttpVerbose<cr>', desc = 'Toggle verbose for HTTP request' },
          { '<leader>ha', '<cmd>HttpRunAll<cr>', desc = 'Run all HTTP requests' },
          { '<leader>hf', '<cmd>Telescope http_client http_env_files<cr>', desc = 'Select HTTP env file (Telescope)' },
          { '<leader>hh', '<cmd>Telescope http_client http_envs<cr>', desc = 'Select HTTP env (Telescope)' },
          { '<leader>hp', '<cmd>HttpProfiling<cr>', desc = 'Toggle HttpProfiling request profiling' },
          { '<leader>hc', '<cmd>HttpCopyCurl<cr>', desc = 'Copy curl command for HTTP request' },
        }

        vim.api.nvim_create_autocmd('FileType', {
          pattern = 'http',
          callback = function(args)
            for _, keymap in pairs(keymaps) do
              keymap = vim.tbl_deep_extend('force', { buf = args.buf }, keymap)
              Snacks.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap)
            end
          end,
        })

        -- Setup the keys for the buffer that triggers the initial setup
        for _, keymap in pairs(keymaps) do
          keymap = vim.tbl_deep_extend('force', { buf = ev.buf }, keymap)
          Snacks.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap)
        end

        -- Set up Telescope integration if available
        if pcall(require, 'telescope') then require('telescope').load_extension 'http_client' end
      end,
    })
  end

  do -- [[ Debugger ]]
    vim.pack.add {
      gh 'mfussenegger/nvim-dap',
      gh 'rcarriga/nvim-dap-ui',
      gh 'nvim-neotest/nvim-nio',
      gh 'mason-org/mason.nvim',
      gh 'jay-babu/mason-nvim-dap.nvim',
    }

    local dap_python_enabled = false
    local dap_go_enabled = false
    local dap_zig_enabled = false
    -- WARNING: enabling this may cause problem while debugging zig code
    local enable_virtual_text = false
    local ensure_installed = {}

    if utils.executable 'gopls' then
      dap_go_enabled = true
      table.insert(ensure_installed, 'delve')
      vim.pack.add {
        gh 'leoluz/nvim-dap-go',
      }
    end

    if utils.executable 'zls' then
      dap_zig_enabled = true
      -- https://github.com/vadimcn/codelldb
      table.insert(ensure_installed, 'codelldb')
      table.insert(treesitter_parsers, 'zig')
    end

    if vim.lsp.is_enabled 'pyright' then
      dap_python_enabled = true
      table.insert(ensure_installed, 'python')
      vim.pack.add {
        gh 'mfussenegger/nvim-dap-python',
      }
    end

    if enable_virtual_text then vim.pack.add {
      gh 'theHamsta/nvim-dap-virtual-text',
    } end

    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = false,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        python = function(config)
          for _, conf in ipairs(config.configurations) do
            conf['justMyCode'] = false
          end

          require('mason-nvim-dap').default_setup(config)
        end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = ensure_installed,
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {}

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    if enable_virtual_text then require('nvim-dap-virtual-text').setup {} end

    if dap_python_enabled then require('dap-python').setup 'uv' end

    if dap_zig_enabled then
      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        host = '127.0.0.1',
        executable = {
          command = 'codelldb',
          args = { '--port', '${port}' },
        },
      }

      dap.configurations.zig = {
        {
          name = 'Launch',
          type = 'codelldb',
          request = 'launch',
          -- program = '${workspaceFolder}/zig-out/bin/${workspaceFolderBasename}',
          program = function()
            local path = vim.fn.input {
              prompt = 'Path to executable: ',
              default = vim.fn.getcwd() .. '/',
              completion = 'file',
            }
            return (path and path ~= '') and path or dap.ABORT
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
        },
      }
    end

    if dap_go_enabled then
      require('dap-go').setup {
        delve = {
          -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
          detached = vim.fn.has 'win32' == 0,
        },
      }
    end

    --- source: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/dap/core.lua
    ---@param config {args?:string[]|fun():string[]?}
    local function get_args(config)
      local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
      config = vim.deepcopy(config)
      ---@cast args string[]
      config.args = function()
        local new_args = vim.fn.input('Run with args: ', table.concat(args, ' ')) --[[@as string]]
        return vim.split(vim.fn.expand(new_args) --[[@as string]], ' ')
      end
      return config
    end

    local keys = {
      {
        '<leader>dB',
        function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
        desc = 'Debug: Breakpoint Condition',
      },
      { '<leader>db', function() dap.toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
      { '<leader>dc', function() dap.continue() end, desc = 'Debug: Start/Continue' },
      { '<leader>da', function() dap.continue { before = get_args } end, desc = 'Debug: Run with Args' },
      { '<leader>dr', function() dap.restart() end, desc = 'Debug: Restart' },
      { '<leader>dC', function() dap.run_to_cursor() end, desc = 'Debug: Run to Cursor' },
      { '<leader>dg', function() dap.goto_() end, desc = 'Debug: Go to Line (No Execute)' },
      { '<leader>di', function() dap.step_into() end, desc = 'Debug: Step Into' },
      { '<leader>dj', function() dap.down() end, desc = 'Debug: Down' },
      { '<leader>dk', function() dap.up() end, desc = 'Debug: Up' },
      { '<leader>dl', function() dap.run_last() end, desc = 'Debug: Run Last' },
      { '<leader>dO', function() dap.step_out() end, desc = 'Debug: Step Out' },
      { '<leader>do', function() dap.step_over() end, desc = 'Debug: Step Over' },
      { '<leader>dp', function() dap.pause() end, desc = 'Debug: Pause' },
      { '<leader>ds', function() dap.session() end, desc = 'Debug: Session' },
      { '<leader>dt', function() dap.terminate() end, desc = 'Debug: Terminate' },
      -- -------------[DAP UI]-------------
      { '<leader>du', function() dapui.toggle {} end, desc = 'Debug: See last session result.' },
      { '<leader>de', function() dapui.eval() end, desc = 'Dap UI - Eval', mode = { 'n', 'v' } },
    }

    for _, km in pairs(keys) do
      vim.keymap.set(km.mode or 'n', km[1], km[2], { desc = km.desc })
    end
  end

  do -- smart-splits
    -- Smart, seamless, directional navigation and resizing of Neovim + terminal multiplexer splits. Supports tmux, Wezterm, and Kitty. Think about splits in terms of "up/down/left/right".
    --
    -- https://github.com/mrjones2014/smart-splits.nvim

    vim.schedule(function()
      vim.pack.add {
        { src = gh 'mrjones2014/smart-splits.nvim' },
      }

      local sp = require 'smart-splits'
      ---@diagnostic disable-next-line: missing-fields
      sp.setup {
        -- Ignored filetypes (only while resizing)
        ignored_filetypes = { 'NvimTree', 'snacks_picker_list' },
      }

      -- moving between splits
      vim.keymap.set('n', '<C-h>', sp.move_cursor_left)
      vim.keymap.set('n', '<C-j>', sp.move_cursor_down)
      vim.keymap.set('n', '<C-k>', sp.move_cursor_up)
      vim.keymap.set('n', '<C-l>', sp.move_cursor_right)

      -- re-sizing window splits
      -- these keymaps will also accept a range,
      -- for example `10<M-h>` will `resize_left` by `(10 * config.default_amount)`
      vim.keymap.set('n', '<M-h>', sp.resize_left, { desc = 'resize window split to the left side' })
      vim.keymap.set('n', '<M-j>', sp.resize_down, { desc = 'resize window split to the bottom side' })
      vim.keymap.set('n', '<M-k>', sp.resize_up, { desc = 'resize window split to the top side' })
      vim.keymap.set('n', '<M-l>', sp.resize_right, { desc = 'resize window split to the right side' })
    end)
  end

  if treesitter_installed then
    require('nvim-treesitter').install(treesitter_parsers)

    vim.api.nvim_create_user_command('SyncTSInstall', function()
      require('nvim-treesitter').install(treesitter_parsers):wait(300000) -- 5 mins
      vim.cmd 'quitall'
    end, { nargs = 0, desc = 'Install treesitter parsers with one minute waiting time and close/exit neovim' })
  end
end

-------------------------------------------------------------------------------
-- HEADLESS BOOTSTRAP AUTOMATION
-- Automatically provisions the environment when running headlessly
-------------------------------------------------------------------------------
if vim.env.RUN_BOOTSTRAP then
  do
    -- Force real-time terminal output since standard print() can buffer in headless mode
    local function log(msg)
      io.write('[Bootstrap] ' .. msg .. '\n')
      io.flush()
    end

    vim.schedule(function()
      log '=== Headless Bootstrap Started ==='

      -- 1. TRIGGER PLUGIN INSTALLATION
      log 'Syncing plugins via vim.pack...'
      pcall(function() vim.pack.update(nil, { target = 'lockfile', force = true }) end)

      -- Setup a timer to wait for async git operations to settle.
      -- Every time a plugin downloads, this timer resets. Once network activity
      -- stops for 3 seconds, we move on to Tree-sitter and Mason.
      local debounce_timer = vim.uv.new_timer()

      local function run_post_install_hooks()
        if debounce_timer then
          debounce_timer:stop()
          debounce_timer:close()
        end
        log 'Plugin synchronization settled.'

        -- 2. TREE-SITTER PHASE
        log '→ Setting up Tree-sitter...'
        vim.cmd 'packadd nvim-treesitter'
        local ts_ok, ts = pcall(require, 'nvim-treesitter')
        if ts_ok then
          local parsers = { 'c', 'lua', 'vim', 'vimdoc', 'query' }
          log('Compiling parsers: ' .. table.concat(parsers, ', '))
          ts.install(parsers):wait(300000) -- Blocks the thread for up to 5 minutes
          log '✓ Tree-sitter compilation complete.'
        else
          log '⚠ nvim-treesitter could not be loaded.'
        end

        -- 3. MASON PHASE
        log '→ Setting up Mason LSPs & Debuggers...'
        vim.cmd 'packadd mason.nvim'
        local mason_ok, mason = pcall(require, 'mason')
        if mason_ok then
          mason.setup()
          local registry = require 'mason-registry'

          log 'Refreshing Mason registry index...'
          registry.refresh(function()
            local tools = { 'lua-language-server', 'stylua' }

            -- Fire manual installations for explicit tools if they don't exist
            for _, tool_name in ipairs(tools) do
              if registry.has_package(tool_name) then
                local pkg = registry.get_package(tool_name)
                if not pkg:is_installed() and not pkg:is_installing() then
                  log('Starting explicit installation: ' .. tool_name)
                  pkg:install {}
                end
              end
            end

            -- Pause briefly (3 seconds) to allow parallel autoinstall hooks
            -- (from mason-lspconfig or mason-tool-installer) to initialize their tasks
            log 'Allowing background autoinstall hooks to stabilize...'
            vim.wait(3000, function() return false end)

            -- Now, poll ALL possible packages globally until absolutely nothing is installing anymore
            log 'Monitoring all active Mason installation handles globally...'
            local last_active_pkg = ''
            local success = vim.wait(300000, function()
              for _, pkg in ipairs(registry.get_all_packages()) do
                if pkg:is_installing() then
                  if last_active_pkg ~= pkg.name then
                    log('Background task busy: Installing ' .. pkg.name .. '...')
                    last_active_pkg = pkg.name
                  end
                  return false -- Something is actively downloading; keep waiting
                end
              end
              return true -- Absolutely everything is clear!
            end, 500)

            if success then
              log '✓ All Mason packages/tools are completely finished installing.'
            else
              log '⚠ Mason synchronization timed out.'
            end

            -- 4. TEARDOWN
            log '=== Headless Bootstrap Complete! Exiting... ==='
            vim.cmd 'qa!'
          end)
        else
          log '⚠ mason.nvim could not be loaded.'
          log '=== Headless Bootstrap Complete! Exiting... ==='
          vim.cmd 'qa!'
        end
      end

      -- Listen for installation events to track progress and reset the timer
      vim.api.nvim_create_autocmd('PackChanged', {
        callback = function(ev)
          if ev.data and ev.data.kind == 'install' then log('Downloaded: ' .. (ev.data.spec.name or 'unknown plugin')) end
          if debounce_timer ~= nil then
            debounce_timer:stop()
            debounce_timer:start(3000, 0, vim.schedule_wrap(run_post_install_hooks))
          end
        end,
      })

      -- Fallback: If plugins are already up-to-date, start hooks after 3 seconds
      if debounce_timer ~= nil then debounce_timer:start(3000, 0, vim.schedule_wrap(run_post_install_hooks)) end

      -- Ultimate Fail-Safe: Prevent infinite terminal hangs if a process locks up
      vim.defer_fn(function()
        log 'CRITICAL: Bootstrap timed out after 10 minutes. Aborting.'
        vim.cmd 'cquit'
      end, 600000)
    end)
  end
end
