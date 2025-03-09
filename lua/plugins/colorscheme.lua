-- https://github.com/sainnhe/sonokai

_ = {
  'sainnhe/sonokai',
  lazy = false,
  priority = 1000,
  config = function()
    -- :help sonokai
    vim.g.sonokai_transparent_background = 1
    vim.g.sonokai_disable_italic_comment = 1
    vim.g.sonokai_diagnostic_virtual_text = 'colored'
    vim.cmd.colorscheme('sonokai')
  end,
}

-- https://github.com/rebelot/kanagawa.nvim

return {
  'rebelot/kanagawa.nvim',
  branch = 'master',
  config = function()
    -- NOTE: run :KanagawaCompile command to make sure the changes are applied (after saving and restarting nvim)
    require('kanagawa').setup({
      compile = false, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = false },
      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      -- colors = { -- add/modify theme and palette colors
      --   palette = {},
      --   theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      -- },
      ---@diagnostic disable-next-line: unused-local
      overrides = function(colors) -- add/modify highlights
        return {
          ['@markup.link.url.markdown_inline'] = { link = 'Special' }, -- (url)
          ['@markup.link.label.markdown_inline'] = { link = 'WarningMsg' }, -- [label]
          ['@markup.italic.markdown_inline'] = { link = 'Exception' }, -- *italic*
          ['@markup.raw.markdown_inline'] = { link = 'String' }, -- `code`
          ['@markup.list.markdown'] = { link = 'Function' }, -- + list
          ['@markup.quote.markdown'] = { link = 'Error' }, -- > blockcode
          ['@markup.list.checked.markdown'] = { link = 'WarningMsg' }, -- - [X] checked list item
        }
      end,
      theme = 'dragon', -- Load "wave" theme when 'background' option is not set
      background = { -- map the value of 'background' option to a theme
        dark = 'dragon', -- try "dragon" !
      },
    })

    -- setup must be called before loading
    vim.cmd('colorscheme kanagawa')
  end,
}

-- -- vim: ts=2 sts=2 sw=2 et
