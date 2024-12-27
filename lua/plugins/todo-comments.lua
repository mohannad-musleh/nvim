-- Highlight, list and search todo comments in your projects
--
-- https://github.com/folke/todo-comments.nvim
--
-- NOTE: this plugin integrates with Telescope and Trouble plugins

return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      signs = false,
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
