-- https://github.com/sainnhe/sonokai

return {
  'sainnhe/sonokai',
  lazy = false,
  priority = 1000,
  config = function()
    -- :help sonokai
    vim.g.sonokai_transparent_background = 1
    vim.g.sonokai_disable_italic_comment = 1
    vim.g.sonokai_diagnostic_virtual_text = 'colored'
    vim.cmd.colorscheme('sonokai')
  end,
}

-- -- vim: ts=2 sts=2 sw=2 et
