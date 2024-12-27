local enable_go = vim.fn.executable('go') == 1
local enable_python = vim.fn.executable('python') == 1

--- source: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/dap/core.lua
---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.input('Run with args: ', table.concat(args, ' ')) --[[@as string]]
    return vim.split(vim.fn.expand(new_args) --[[@as string]], ' ')
  end
  return config
end

local dependencies = {
  -- Creates a beautiful debugger UI
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio' },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Toggle Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Dap UI - Eval", mode = {"n", "v"} },
    },
    opts = {},
  },

  'williamboman/mason.nvim',
  'jay-babu/mason-nvim-dap.nvim',
  'theHamsta/nvim-dap-virtual-text',
}

if enable_go then
  table.insert(dependencies, {
    'leoluz/nvim-dap-go',
    opts = {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has('win32') == 0,
      },
    },
  })
end

return {
  'mfussenegger/nvim-dap',
  dependencies = dependencies,
  -- stylua: ignore
  keys = {
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = '[DAP] Breakpoint Condition' },
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = '[DAP] Toggle Breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = '[DAP] Continue' },
      { '<leader>da', function() require('dap').continue({ before = get_args }) end, desc = '[DAP] Run with Args' },
      { '<leader>dr', function() require('dap').restart() end, desc = '[DAP] Restart' },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = '[DAP] Run to Cursor' },
      { '<leader>dg', function() require('dap').goto_() end, desc = '[DAP] Go to Line (No Execute)' },
      { '<leader>di', function() require('dap').step_into() end, desc = '[DAP] Step Into' },
      { '<leader>dj', function() require('dap').down() end, desc = '[DAP] Down' },
      { '<leader>dk', function() require('dap').up() end, desc = '[DAP] Up' },
      { '<leader>dl', function() require('dap').run_last() end, desc = '[DAP] Run Last' },
      { '<leader>do', function() require('dap').step_out() end, desc = '[DAP] Step Out' },
      { '<leader>dO', function() require('dap').step_over() end, desc = '[DAP] Step Over' },
      { '<leader>dp', function() require('dap').pause() end, desc = '[DAP] Pause' },
      { '<leader>ds', function() require('dap').session() end, desc = '[DAP] Session' },
      { '<leader>dt', function() require('dap').terminate() end, desc = '[DAP] Terminate' },
      { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = '[DAP] Widgets' },
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')
    local dap_vt = require('nvim-dap-virtual-text')
    local mason_dap = require('mason-nvim-dap')

    dap_vt.setup({ enabled = true })

    local ensure_installed = {}

    if enable_go then
      table.insert(ensure_installed, 'delve')
    end

    if enable_python then
      table.insert(ensure_installed, 'python')
    end

    mason_dap.setup({
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = ensure_installed,
    })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}

-- vim: ts=2 sts=2 sw=2 et
