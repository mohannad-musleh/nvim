-- Getting you where you want with the fewest keystrokes.
--
-- https://github.com/ThePrimeagen/harpoon/tree/harpoon2

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  ---@module 'harpoon'
  ---@type HarpoonPartialConfig
  opts = {},
  config = function(_, opts)
    local harpoon = require('harpoon')

    harpoon:setup(opts)

    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Show harpoon list' })

    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():add()
    end, { desc = '[H]arpoon [A]dd' })

    vim.keymap.set('n', 'hp', function()
      harpoon:list():prev({ ui_nav_wrap = true })
    end, { desc = 'Jump to [H]arpoon [P]revious item' })

    vim.keymap.set('n', 'hn', function()
      harpoon:list():next({ ui_nav_wrap = true })
    end, { desc = 'Jump to [H]arpoon [N]ext item' })

    vim.keymap.set('n', 'h1', function()
      harpoon:list():select(1)
    end, { desc = 'Jump to [H]arpoon 1st item' })

    vim.keymap.set('n', 'h2', function()
      harpoon:list():select(2)
    end, { desc = 'Jump to [H]arpoon 2nd item' })

    vim.keymap.set('n', 'h3', function()
      harpoon:list():select(3)
    end, { desc = 'Jump to [H]arpoon 3rd item' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
