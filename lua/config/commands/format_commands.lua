vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting globally
    vim.g.disable_autoformat = true
  else
    vim.b.disable_autoformat = true
  end
end, { desc = 'Disable autoformat-on-save (add `!` to disable globally)', bang = true })

vim.api.nvim_create_user_command('FormatEnable', function(args)
  if args.bang then
    vim.g.disable_autoformat = false
  end
  vim.b.disable_autoformat = false
end, {
  desc = '(re)enable autoformat-on-save (add `!` to enable globally -- will disable for the current buffer regadless --)',
  bang = true,
})

-- vim: ts=2 sts=2 sw=2 et
