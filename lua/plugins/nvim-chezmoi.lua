-- A NeoVim plugin that integrates with chezmoi.
--
-- https://github.com/andre-kotake/nvim-chezmoi

return {
  'andre-kotake/nvim-chezmoi',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope.nvim' },
  },
  opts = {
    -- Show extra debug messages.
    debug = false,
    edit = {
      -- Automatically apply file on save. Can be one of: "auto", "confirm" or "never"
      apply_on_save = 'never',
    },
  },
  config = function(_, opts)
    require('nvim-chezmoi').setup(opts)
  end,
}
