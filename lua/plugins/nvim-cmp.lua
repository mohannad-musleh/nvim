-- A completion plugin for neovim coded in Lua.
--
-- https://github.com/hrsh7th/nvim-cmp

return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    'roobert/tailwindcss-colorizer-cmp.nvim',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp-signature-help',
    'hrsh7th/cmp-buffer',
  },
  config = function()
    -- See `:help cmp`
    local cmp = require('cmp')

    -- Get the current sources
    local sources = cmp.get_config().sources or {}
    table.insert(sources, {
      name = 'lazydev',
      -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
      group_index = 0,
    })
    table.insert(sources, { name = 'nvim_lsp' })
    table.insert(sources, { name = 'path' })
    table.insert(sources, { name = 'buffer' })
    table.insert(sources, { name = 'nvim_lsp_signature_help' })

    require('tailwindcss-colorizer-cmp').setup({
      color_square_width = 2,
    })

    ---@module "cmp"
    ---@type cmp.Setup
    cmp.setup({
      sources = sources,
      completion = { completeopt = 'menu,menuone,noinsert' },
      formatting = {
        fields = { 'abbr', 'kind', 'menu' },
        expandable_indicator = true,
        format = function(entry, vim_item)
          -- Tailwind colorizer setup
          vim_item = require('tailwindcss-colorizer-cmp').formatter(entry, vim_item)

          -- change menu (name of source)
          vim_item.menu = ({
            nvim_lsp = '[LSP]',
            buffer = '[Buffer]',
            path = '[Path]',
            emoji = '[Emoji]',
            luasnip = '[LuaSnip]',
            vsnip = '[VSCode Snippet]',
            calc = '[Calc]',
            spell = '[Spell]',
          })[entry.source.name]
          return vim_item
        end,
      },
      mapping = cmp.mapping.preset.insert({
        -- Select the [N]ext item
        ['<C-n>'] = cmp.mapping.select_next_item(),
        -- Select the [P]revious item
        ['<C-p>'] = cmp.mapping.select_prev_item(),

        -- Scroll the documentation window [b]ack / [f]orward
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        -- Accept ([y]es) the completion.
        --  This will auto-import if your LSP supports it.
        --  This will expand snippets if the LSP sent a snippet.
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),

        -- Manually trigger a completion from nvim-cmp.
        --  Generally this not needed, because nvim-cmp will display
        --  completions whenever it has completion options available.
        ['<C-Space>'] = cmp.mapping.complete({}),
      }),
    })

    -- cmp.config.formatting = {
    --   format = require('tailwindcss-colorizer-cmp').formatter,
    -- }
  end,
}

-- vim: ts=2 sts=2 sw=2 et
