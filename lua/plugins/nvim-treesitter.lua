-- Nvim Treesitter configurations and abstraction layer, for better Highlight, edit, and navigate code
--
-- https://github.com/nvim-treesitter/nvim-treesitter
--
-- Additional nvim-treesitter modules:
--
-- Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
-- Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
-- Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  dependencies = {
    'nvim-treesitter/nvim-treesitter-context',
  },
  opts = {
    ensure_installed = {
      'diff',
      'regex',
      'http',
      'bash',
      'c',
      'html',
      'css',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',
      'json',
      'jsonc',
      'jsdoc',
      'javascript',
      'typescript',
      'gotmpl',
      'vue',
    },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      ---@diagnostic disable-next-line: unused-local
      disable = function(lang, bufnr)
        local is_disabled = vim.b[bufnr].nvim_treesitter_disable_highlight
          or vim.g.nvim_treesitter_disable_highlight
          or false

        return is_disabled
      end,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      -- additional_vim_regex_highlighting = { 'ruby' },
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true, disable = { 'ruby' } },
    -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#incremental-selection
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<Enter>', -- set to `false` to disable one of the mappings
        node_incremental = '<Enter>',
        scope_incremental = false,
        node_decremental = '<Backspace>',
      },
    },
  },
  config = function(_, opts)
    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup(opts)

    require('treesitter-context').setup({ max_lines = 10, line_numbers = false })

    -- Jumping to context (upwards)
    vim.keymap.set('n', '[u', function()
      require('treesitter-context').go_to_context(vim.v.count1)
    end, { silent = true, desc = 'Jumping to context (upwards)' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
