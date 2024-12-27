-- Smart, seamless, directional navigation and resizing of Neovim + terminal multiplexer splits. Supports tmux, Wezterm, and Kitty. Think about splits in terms of "up/down/left/right".
--
-- https://github.com/mrjones2014/smart-splits.nvim

return {
  'mrjones2014/smart-splits.nvim',
  lazy = false,
  opts = {},
  config = function(_, opts)
    local sp = require('smart-splits')
    sp.setup(opts)

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
  end,
}

-- vim: ts=2 sts=2 sw=2 et
