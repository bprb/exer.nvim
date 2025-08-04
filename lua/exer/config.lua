local M = {}

local defaults = {
  debug = false,
  disable_default_keymaps = false,
  enable_navigation = false,
  enable_builtin_mods = true,
  config_files = nil,
  ui = {
    height = 0.3,
    list_width = 36,
    auto_toggle = true,
    auto_scroll = true,
  },
  keymaps = {
    { '<leader>ro', 'ExerOpen', 'Open task picker' },
    { '<leader>rr', 'ExerRedo', 'Re-run last task' },
    { '<leader>rx', 'ExerStop', 'Stop all running tasks' },
    { '<A-/>', 'ExerShow', 'Toggle task output window' },
    { '<C-w>t', 'ExerFocusUI', 'Focus task UI' },
    { '<C-j>', 'ExerNavDown', 'Task navigation down' },
    { '<C-k>', 'ExerNavUp', 'Task navigation up' },
    { '<C-h>', 'ExerNavLeft', 'Task navigation left' },
    { '<C-l>', 'ExerNavRight', 'Task navigation right' },
  },
}

local options = nil

function M.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend('force', defaults, opts)

  if options.debug then _G.g_exer_debug = true end

  if options.ui then require('exer.ui').setup(options.ui) end

  M.setupKeymaps()
end

function M.get()
  if options == nil then M.setup() end
  return options
end

function M.setupKeymaps()
  if options.disable_default_keymaps then return end

  local hasLazyKeys = false
  if package.loaded.lazy then
    local ok, lazy_config = pcall(require, 'lazy.core.config')
    if ok and lazy_config.spec and lazy_config.spec.plugins then
      for _, plugin in pairs(lazy_config.spec.plugins) do
        if plugin.name == 'exer.nvim' and plugin.keys then
          hasLazyKeys = true
          break
        end
      end
    end
  end

  if not hasLazyKeys then
    -- Defer keymap setup to ensure they're set after other plugins
    vim.defer_fn(function()
      for _, keyDef in ipairs(options.keymaps) do
        local lhs, cmd, desc = keyDef[1], keyDef[2], keyDef[3]

        -- Skip navigation keymaps if not enabled
        if not options.enable_navigation and (cmd == 'ExerNavDown' or cmd == 'ExerNavUp' or cmd == 'ExerNavLeft' or cmd == 'ExerNavRight') then goto continue end

        -- Always set the keymap to override existing mappings
        vim.api.nvim_set_keymap('n', lhs, '<cmd>' .. cmd .. '<cr>', {
          noremap = true,
          silent = true,
          desc = desc,
        })

        ::continue::
      end
    end, 100) -- Delay 100ms to ensure we run after other plugins
  end
end

return M
