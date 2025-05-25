-- Plugin to improve viewing Markdown files in Neovim
--
-- https://github.com/MeanderingProgrammer/render-markdown.nvim

return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  opts = {
    -- Whether markdown should be rendered by default.
    enabled = false,
  },
  config = true,
}

-- vim: ts=2 sts=2 sw=2 et
