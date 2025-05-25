-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

vim.g.global_ignore_dirs = { '.git', 'node_modules' }

require('config.options')
require('config.keymaps')
require('config.autocommands')
require('config.commands.init')
require('config.lazy')

-- `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
