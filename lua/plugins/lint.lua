-- An asynchronous linter plugin for Neovim complementary to the built-in Language Server Protocol support.
--
-- https://github.com/mfussenegger/nvim-lint

return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {} -- disable all default linters (I like to manually enable them)
    lint.linters_by_ft['markdown'] = nil
    lint.linters_by_ft['vue'] = { 'biomejs' }
    lint.linters_by_ft['javascript'] = { 'biomejs' }
    lint.linters_by_ft['typescript'] = { 'biomejs' }
    lint.linters_by_ft['python'] = { 'ruff' }

    -- Create autocommand which carries out the actual linting
    -- on the specified events.
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        -- Only run the linter in buffers that you can modify in order to
        -- avoid superfluous noise, notably within the handy LSP pop-ups that
        -- describe the hovered symbol using Markdown.
        if vim.opt_local.modifiable:get() then
          lint.try_lint()
        end
      end,
    })

    vim.keymap.set('n', '<leader>l', function()
      lint.try_lint()
    end, { desc = 'Trigger linting for current file' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
