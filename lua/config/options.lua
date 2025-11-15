-- [[ Setting options ]]
-- See `:help vim.opt`
--  For more options, you can see `:help option-list`

local vars = require('vars')

-- Disable line wrapping
vim.opt.wrap = false

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- If you are using a status line that shows the mode, you can change this to `false`
vim.opt.showmode = true

-- Enable break indent
vim.opt.breakindent = true

-- Disable swap file and backup files
vim.opt.swapfile = false
vim.opt.backup = false

-- Save undo history
vim.opt.undodir = vim.fn.stdpath('cache') .. '/undodir'
vim.opt.undofile = true
vim.opt.history = 1000 -- Set the history size

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = vars.short_listchars

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = false

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Minimal number of screen columns to keep before and after the cursor (when moving horizontally).
vim.opt.sidescrolloff = 8
-- Enable exrc (Project local config)
-- This allows to add `.nvim.lua` file per project and run a Lua code to configure neovim for that project -- e.g. define global variables --
-- :help 'exrc'
vim.opt.exrc = true

-- Better :mksession
--
-- :help sessionoptions
vim.opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

vim.filetype.add({
  filename = {
    ['tmux.conf'] = 'tmux',
  },
  extension = {
    tmpl = 'gotmpl',
    t = 'gotmpl',
    ejson = 'json',
  },
})

-- Enable NeoVim builtin spelling checker
-- learn more here: https://vimtricks.com/p/vim-spell-check/
vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }
vim.opt.spelloptions:append('camel')
vim.opt.spellcapcheck = '' -- disable checking for capital letters at the start of sentences

-- tabs
vim.opt.tabstop = 4 -- number of space characters per tab
vim.opt.shiftwidth = 4 -- spaces per indentation level
vim.opt.softtabstop = 4
vim.opt.expandtab = true -- expand tab input with spaces characters
vim.opt.smartindent = true -- syntax aware indentations for newline inserts
vim.opt.shiftround = true -- round the indents to a multiple of shiftwidth when using the `>` and `<` keys

vim.opt.colorcolumn = '80'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
