-- The undo history visualizer for VIM
--
-- https://github.com/mbbill/undotree

return {
  'mbbill/undotree',
  config = function()
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle undotree' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
