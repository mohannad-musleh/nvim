vim.filetype.add {
  pattern = {
    -- Matches exactly ".env" or files starting with ".env" (e.g., .env.local, .env.prod)
    ['%.env.*'] = 'env',
    ['%.env'] = 'env',
  },
  filename = {
    ['tmux.conf'] = 'tmux',
    ['mise.lock'] = 'toml',
  },
  extension = {
    tmpl = 'gotmpl',
    t = 'gotmpl',
    ejson = 'json',
  },
}
