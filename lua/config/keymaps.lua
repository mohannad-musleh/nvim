-- See `:help vim.keymap.set()`

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Allow moving the cursor through wrapped lines with j, k
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- delete single character without copying into register
vim.keymap.set('n', 'x', '"_x', { noremap = true, silent = true })

-- In visual mode, delete selected text and paste after that.
vim.keymap.set('x', '<leader>r', [["_dP]])

-- In visual mode, delete selected text and paste after that (from system clipboard).
vim.keymap.set('x', '<leader>R', [["_d"+P]])

-- Clear highlights on search when pressing <Esc> in normal mode
-- See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<C-S-h>', '<C-w>H', { desc = 'Move window to the left' })
vim.keymap.set('n', '<C-S-l>', '<C-w>L', { desc = 'Move window to the right' })
vim.keymap.set('n', '<C-S-j>', '<C-w>J', { desc = 'Move window to the lower' })
vim.keymap.set('n', '<C-S-k>', '<C-w>K', { desc = 'Move window to the upper' })

-- Centralize the cursor while jumping
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

-- Yank to clipboard keymaps
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

-- Paste from clipboard keymaps
vim.keymap.set({ 'n', 'v' }, '<leader>p', [["+P]])

vim.keymap.set('n', '<leader>dch', function()
  local word = vim.fn.input('Type a word contained in the command(s) to match and remove:')
  if word and word ~= '' then
    vim.fn.histdel(':', '\\c.*' .. word .. '.*')
    vim.cmd('wsh!') -- reflect the history changes to the disk (Write to the default ShaDa file)
  end
end, { silent = true, desc = 'Delete commands from commands history matched by a pattern/regex (case-insensitive)' })

vim.keymap.set('n', '<leader>dcH', function()
  local word = vim.fn.input('Type a word contained in the command(s) to match and remove:')
  if word and word ~= '' then
    vim.fn.histdel(':', '.*' .. word .. '.*')
    vim.cmd('wsh!') -- reflect the history changes to the disk (Write to the default ShaDa file)
  end
end, { silent = true, desc = 'Delete commands from commands history matched by a pattern/regex (case-sensitive)' })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
