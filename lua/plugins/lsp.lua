---Disable LSP's completion
---
---@param client vim.lsp.Client
local disable_lsp_completion = function(client)
  ---@diagnostic disable-next-line: assign-type-mismatch
  client.server_capabilities.completionProvider = false
end

return { -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        -- { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  -- LSP Configuration & Plugins
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'mason-org/mason.nvim', config = true }, -- NOTE: Must be loaded before dependents
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- JSON & Yaml schema provider (used with jsonls)
      'b0o/SchemaStore.nvim',
      {
        'ziglang/zig.vim',
        enabled = vim.fn.executable('zig') == 1,
        init = function()
          -- don't show parse errors in a separate window
          vim.g.zig_fmt_parse_errors = 0
          -- disable format-on-save from `ziglang/zig.vim`
          vim.g.zig_fmt_autosave = 0
        end,
        config = function()
          vim.api.nvim_create_autocmd({ 'BufReadPre' }, {
            group = vim.api.nvim_create_augroup('zig.vim', { clear = true }),
            pattern = { '*.zig', '*.zon' },
            callback = function(ev)
              -- Formatting with ZLS matches `zig fmt`.
              -- The Zig FAQ answers some questions about `zig fmt`:
              -- https://github.com/ziglang/zig/wiki/FAQ
              vim.api.nvim_buf_set_keymap(
                ev.buf,
                'n',
                '<leader>f',
                ':lua vim.lsp.buf.format()<CR>',
                { noremap = true, silent = true }
              )
              -- vim.lsp.buf.format()
            end,
          })
        end,
      },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
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

          -- Find references for the word under your cursor.
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client ~= nil and vim.g.disable_lsp_autocomplete then
            disable_lsp_completion(client)
            vim.notify_once('LSP auto complete disabled for ' .. vim.bo[event.buf].filetype, vim.log.levels.INFO)
          end

          if client ~= nil and client.name == 'ruff' then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
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
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok then
        capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
      end

      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      ---@type { [string]: table | nil }
      local servers = {
        clangd = {},
        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      if vim.fn.executable('go') == 1 then
        servers['gopls'] = {}
      end

      if vim.fn.executable('zig') == 1 then
        servers['zls'] = {}
      end

      if vim.fn.executable('docker') == 1 then
        servers['dockerls'] = {}
        servers['docker_compose_language_service'] = {}
      end

      if vim.fn.executable('python') == 1 then
        local ruff_conf = {}

        local py_path = vim.fn.exepath('python')
        local dir_path = vim.fs.dirname(py_path)
        local ruff_path = vim.fs.joinpath(dir_path, 'ruff')
        if vim.fn.executable(ruff_path) == 1 then
          -- If current project has virtualenv with `ruff` installed, use the project `ruff` instead of the global one.
          -- INFO: the logic assumes the `python` command points to the one in the virtualenv,
          --  make sure the virtualenv is active before open neovim -- this done automatically when using Mise --.
          ruff_conf.cmd = { ruff_path, 'server' }

          servers['mypy'] = {}
          servers['ruff'] = ruff_conf
          servers['pyright'] = {
            settings = {
              pyright = {
                disableOrganizeImports = true,
              },
            },
          }

          -- NOTE: the last time I tried "basedpyright", It didn't work as expected, so, I'm using pyright for now.
          -- servers['basedpyright'] = {
          --   settings = {
          --     basedpyright = {
          --       disableOrganizeImports = true,
          --       analysis = {
          --         -- ignore = { '*' },
          --         autoSearchPaths = true,
          --         useLibraryCodeForTypes = true,
          --         typeCheckingMode = 'standard',
          --         diagnosticMode = 'openFilesOnly',
          --         autoImportCompletions = true,
          --       },
          --     },
          --   },
          -- }
        end
      end

      if vim.fn.executable('npm') == 1 then
        local vue_language_server_path = vim.fn.stdpath('data')
          .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

        if vim.fn.isdirectory(vue_language_server_path) == 1 then
          local vue_plugin = {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
            configNamespace = 'typescript',
          }

          vim.lsp.config('vtsls', {
            settings = {
              vtsls = {
                tsserver = {
                  globalPlugins = {
                    vue_plugin,
                  },
                },
              },
            },
            filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
          })
        end

        servers = vim.tbl_extend('force', servers, {
          html = {},
          cssls = {},
          emmet_language_server = {
            filetypes = { 'css', 'html', 'javascript', 'javascriptreact', 'scss', 'pug', 'typescriptreact', 'vue' },
          },
          jsonls = {
            init_options = {
              provideFormatter = false,
            },
            on_new_config = function(new_config)
              -- lazy load schemastore
              new_config.settings.json.schemas = new_config.settings.json.schemas or {}
              vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
            end,
            settings = {
              json = {
                format = {
                  enable = false,
                },
                validate = { enable = true },
              },
            },
          },
          tailwindcss = {
            classAttributes = { 'class', ':class', 'v-bind:class', 'className', 'class:list', 'classList', 'ngClass' },
            includeLanguages = {
              htmlangular = 'html',
              templ = 'html',
            },
            lint = {
              cssConflict = 'warning',
              invalidApply = 'error',
              invalidConfigPath = 'error',
              invalidScreen = 'error',
              invalidTailwindDirective = 'error',
              invalidVariant = 'error',
              recommendedVariantOrder = 'warning',
            },
            validate = true,
          },
          vue_ls = {},
          biome = {
            single_file_support = true,
            on_new_config = function(new_config, new_root_dir)
              local biome_global_config_path = os.getenv('GLOBAL_BIOME_CONFIG_PATH')
              if biome_global_config_path == nil or biome_global_config_path == '' then
                return
              end

              if not new_config.root_dir(new_root_dir, 0) then
                if not (vim.uv or vim.loop).fs_stat(biome_global_config_path) then
                  return
                end

                -- vim.notify('Fallback to biome global config file', vim.log.levels.DEBUG, { timeout = false })
                new_config.cmd_env = new_config.cmd_env or {}
                new_config.cmd_env['BIOME_CONFIG_PATH'] = biome_global_config_path
              end
            end,
          },
        })
      end

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

      require('mason-lspconfig').setup({
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      })
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
