-- A minimal 🤏 HTTP-client 🐼 interface 🖥️ for Neovim ❤️.
--
-- https://github.com/mistweaverco/kulala.nvim

local default_mode = { 'n', 'v' }
local default_ft = { 'http', 'rest', 'text.kulala_ui' }

return {
  {
    'mistweaverco/kulala.nvim',
    ft = { 'http', 'rest' },
    opts = {
      ui = {
        default_view = 'headers_body',
        -- enable/disable variable info text
        -- this will show the variable name and value as float
        -- possible values: false, "float"
        show_variable_info_text = 'float',
      },
      global_keymaps = {
        global_keymaps = {
          ['Send request'] = { -- sets global mapping
            '<leader>hs',
            function()
              require('kulala').run()
            end,
            mode = default_mode,
            ft = default_ft,
          },
          ['Send all requests'] = {
            '<leader>ha',
            function()
              require('kulala').run_all()
            end,
            mode = default_mode,
            ft = default_ft,
          },
          ['Replay the last request'] = {
            '<leader>hr',
            function()
              require('kulala').replay()
            end,
            ft = default_ft,
          },
          ['Clear responses history'] = {
            '<leader>hx',
            function()
              require('kulala.ui').clear_responses_history()
            end,
            ft = default_ft,
          },
          ['Clear globals'] = {
            '<leader>hgx',
            function()
              require('kulala').scripts_clear_global()
            end,
            ft = default_ft,
          },
          ['Clear cached files'] = {
            '<leader>hcx',
            function()
              require('kulala').clear_cached_files()
            end,
            ft = default_ft,
          },
        },
      },
    },
  },
}
