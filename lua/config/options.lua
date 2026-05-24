-- [[ Setting options ]]
-- See `:help vim.o`
--  For more options, you can see `:help option-list`

local vars = require 'vars'

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Disable line wrapping
vim.o.wrap = false

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- If you are using a status line that shows the mode, you can change this to `false`
vim.o.showmode = true

-- Enable break indent
vim.o.breakindent = true

-- Disable swap file and backup files
vim.o.swapfile = false
vim.o.backup = false

-- Save undo history
vim.o.undodir = vim.fs.joinpath(vim.fn.stdpath 'cache', 'undodir')
vim.o.undofile = true
vim.o.history = 1000 -- Set the history size

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.o.list = true
vim.o.listchars = vars.short_listchars

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = false

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- Minimal number of screen columns to keep before and after the cursor (when moving horizontally).
vim.o.sidescrolloff = 8

-- Enable exrc (Project local config)
-- This allows to add `.nvim.lua` file per project and run a Lua code to configure neovim for that project -- e.g. define global variables --
-- :help 'exrc'
vim.o.exrc = true

-- Better :mksession
--
-- :help sessionoptions
vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

-- Enable NeoVim builtin spelling checker
-- learn more here: https://vimtricks.com/p/vim-spell-check/
vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }
vim.opt.spelloptions:append 'camel'
vim.opt.spellcapcheck = '' -- disable checking for capital letters at the start of sentences

-- tabs
vim.o.tabstop = 4 -- number of space characters per tab
vim.o.shiftwidth = 4 -- spaces per indentation level
vim.o.softtabstop = 4
vim.o.expandtab = true -- expand tab input with spaces characters
vim.o.smartindent = true -- syntax aware indentations for newline inserts
vim.o.shiftround = true -- round the indents to a multiple of shiftwidth when using the `>` and `<` keys

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
