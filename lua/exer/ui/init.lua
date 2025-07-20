local M = {}

local cfgs = require('exer.ui.config')
local wins = require('exer.ui.windows')
local rndr = require('exer.ui.render')
local evts = require('exer.ui.events')
local kmps = require('exer.ui.keymaps')
local co = require('exer.core')

local prevWin = nil

function M.showList(skipFocusList)
  evts.initAutoCmd()

  if wins.isValid('list') then
    rndr.renderList()

    if not skipFocusList then wins.focus('list') end

    local tasks = co.tsk.getAll()
    co.lg.debug('UI already exists, task count: ' .. #tasks, 'UI')
    co.lg.debug('Current focus task: ' .. tostring(evts.getFocusTask()), 'UI')

    if #tasks > 0 and not evts.getFocusTask() then
      local taskToFocus = nil

      -- Try to restore last focused task
      if _G.g_exer_last_focused_task then
        co.lg.debug('Last focused task ID: ' .. tostring(_G.g_exer_last_focused_task), 'UI')
        for _, task in ipairs(tasks) do
          if task.id == _G.g_exer_last_focused_task then
            taskToFocus = task.id
            break
          end
        end
      end

      -- If last focused task not found, select first task
      if not taskToFocus then taskToFocus = tasks[1].id end

      co.lg.debug('Setting focus to task: ' .. tostring(taskToFocus), 'UI')
      evts.setFocusTask(taskToFocus)
    end

    return
  end

  if not prevWin then prevWin = vim.api.nvim_get_current_win() end

  local _, listB, _, palB = wins.createMain(cfgs.all())

  wins.createKeysHelp(cfgs.all())
  wins.createScrollStatus(cfgs.all())

  kmps.setupListKeymaps(listB)
  kmps.setupPanelKeymaps(palB)

  vim.api.nvim_create_autocmd('VimResized', {
    callback = function() wins.resize() end,
    desc = 'Resize task UI windows on terminal resize',
  })

  wins.focus('list')
  rndr.renderList()

  evts.startTimer()

  -- Auto focus last selected task or first available task
  local tasks = co.tsk.getAll()
  co.lg.debug('UI first creation, task count: ' .. #tasks, 'UI')

  if #tasks > 0 then
    local taskToFocus = nil

    -- Try to restore last focused task
    if _G.g_exer_last_focused_task then
      co.lg.debug('Last focused task ID: ' .. tostring(_G.g_exer_last_focused_task), 'UI')
      for _, task in ipairs(tasks) do
        if task.id == _G.g_exer_last_focused_task then
          taskToFocus = task.id
          break
        end
      end
    end

    -- If last focused task not found, select first task
    if not taskToFocus then taskToFocus = tasks[1].id end

    co.lg.debug('Setting focus to task (first creation): ' .. tostring(taskToFocus), 'UI')
    evts.setFocusTask(taskToFocus, true) -- Force update on UI creation
  else
    co.lg.debug('No tasks available', 'UI')
  end
end

function M.showTskPal(tid, autoFocus)
  autoFocus = autoFocus or false

  if not wins.isValid('panel') then
    M.showList()
    if not wins.isValid('panel') then return end
  end

  wins.createPanelBuffer(tid)

  local palB = wins.palB
  if palB then kmps.setupPanelKeymaps(palB) end

  evts.showTaskPanel(tid, autoFocus)
end

function M.close()
  evts.cleanup()
  wins.close()

  if prevWin and vim.api.nvim_win_is_valid(prevWin) then vim.api.nvim_set_current_win(prevWin) end

  prevWin = nil
end

function M.toggle()
  if wins.isOpen() then
    M.close()
    return
  end

  prevWin = vim.api.nvim_get_current_win()
  M.showList()
end

function M.setup(opts)
  local cfg = cfgs.setup(opts)
  evts.setAutoScroll(cfg.auto_scroll)
end

function M.focusUI()
  if wins.isOpen() then
    if wins.isValid('list') then
      wins.focus('list')
    elseif wins.isValid('panel') then
      wins.focus('panel')
    end
  else
    M.showList()
  end
end

function M.smartNav(direction) require('exer.ui.keymaps').smartNav(direction) end

M.setup({})

return M
