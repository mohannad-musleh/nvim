-- Cloak allows you to overlay *'s over defined patterns in defined files.
--
-- https://github.com/laytan/cloak.nvim

return {
  'laytan/cloak.nvim',
  opts = {
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
          '.env*',
          'wrangler.toml',
          '.dev.vars',
        },
        cloak_pattern = { '=.+', ':.+' },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
