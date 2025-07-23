local vmd = vim.api.nvim_create_user_command
local co = require('exer.core')
local M = {}

M.setup = function(opts)
  local config = require('exer.config')
  config.setup(opts)

  local cfg = config.get()

  if cfg.debug then
    co.lg.logToFile = true
    co.lg.info('=== EXER DEBUG MODE ENABLED ===', 'Setup')
    co.lg.info('Log file: ' .. co.lg.logFile, 'Setup')
    co.lg.debug('Global debug flag set: ' .. tostring(_G.g_exer_debug), 'Setup')
  end

  vmd('ExerOpen', function() co.picker.show() end, { desc = 'Open the exer' })

  vmd('ExerShow', function() require('exer.ui').toggle() end, { desc = 'Toggle the exer results' })
  vmd('ExerFocusUI', function() require('exer.ui').focusUI() end, { desc = 'Focus task UI' })
  vmd('ExerNavDown', function() require('exer.ui').smartNav('down') end, { desc = 'Task navigation down' })
  vmd('ExerNavUp', function() require('exer.ui').smartNav('up') end, { desc = 'Task navigation up' })
  vmd('ExerNavLeft', function() require('exer.ui').smartNav('left') end, { desc = 'Task navigation left' })
  vmd('ExerNavRight', function() require('exer.ui').smartNav('right') end, { desc = 'Task navigation right' })

  vmd('ExerStop', function()
    local stopped = co.tsk.stopAll()
    co.utils.msg(string.format('Stopped %d running task(s).', stopped), vim.log.levels.INFO)
  end, { desc = 'Stop all running tasks' })

  vmd('ExerRedo', function()
    -- check compound task id
    if _G.g_exer_last_compound_id then
      local proj = require('exer.proj')
      local acts = proj.getActs()
      for _, act in ipairs(acts) do
        if act.id == _G.g_exer_last_compound_id then
          local executor = require('exer.proj.executor')
          executor.executeAct(act, acts)
          return
        end
      end
      co.utils.msg('Compound task not found: ' .. _G.g_exer_last_compound_id, vim.log.levels.WARN)
    end

    local all_tasks = co.tsk.getAll()
    if #all_tasks == 0 then
      co.utils.msg('No previous task found.', vim.log.levels.INFO)
      return
    end

    local lastT = all_tasks[1]
    co.runner.run({
      name = lastT.name,
      cmd = lastT.cmd,
      opts = lastT.opts,
    })
  end, { desc = 'Redo the last task' })
end

return M
