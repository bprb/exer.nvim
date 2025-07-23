local M = {}
local co = require('exer.core')
local render = require('exer.ui.render')
local windows = require('exer.ui.windows')

local state = {
  timer = nil,
  autoCmdGrp = nil,
  focusId = nil,
  autoScroll = true,
}

local function focus(taskId, forceUpdate)
  local co = require('exer.core')
  co.lg.debug('focus() called with taskId: ' .. tostring(taskId) .. ', current focusId: ' .. tostring(state.focusId) .. ', forceUpdate: ' .. tostring(forceUpdate), 'Events')

  if state.focusId ~= taskId or forceUpdate then
    state.focusId = taskId
    -- Remember last focused task globally
    if taskId then _G.g_exer_last_focused_task = taskId end
    if taskId then
      -- Always show task panel when focusing a task
      M.showTaskPanel(taskId)
    else
      co.lg.debug('taskId is nil, not showing panel', 'Events')
    end
  else
    co.lg.debug('taskId same as current focusId, skipping', 'Events')
  end
end

local function refreshPanel(tid, forceFull)
  if not tid then return end

  if not windows.isValid('panel') then
    local ui = require('exer.ui')
    ui.showList(true)
  end

  if forceFull then
    M.showTaskPanel(tid, true)
  else
    render.renderPanel(tid, state.autoScroll)
  end
end

local function onAutoCmdTsk(args)
  local pattern = args.match or args.pattern

  if pattern == 'RazTaskComplete' then
    if args.data and args.data.tskId == state.focusId then
      local tid = state.focusId
      -- Don't auto-focus on task completion, just update panel content
      vim.defer_fn(function()
        if not windows.isValid('panel') then
          local ui = require('exer.ui')
          ui.showList(true)
        end
        render.renderPanel(tid, state.autoScroll)
      end, 500)
    end
    return
  end

  if not windows.isValidBuf('list') then return end

  vim.schedule(function()
    render.renderList()

    if pattern == 'RazTaskCreated' or pattern == 'RazTaskStarted' then
      if args.data and args.data.tskId then
        local taskId = args.data.tskId
        if pattern == 'RazTaskStarted' then
          state.focusId = taskId
          refreshPanel(taskId, true)
        else
          focus(taskId)
        end
      end
    elseif pattern == 'RazTaskOutput' then
      if args.data and args.data.tskId == state.focusId then render.renderPanel(state.focusId, state.autoScroll) end
    end
  end)
end

local function startUpdTimer()
  if state.timer then state.timer:stop() end

  state.timer = vim.uv.new_timer()

  local cntUpd = 0
  state.timer:start(
    500,
    500,
    vim.schedule_wrap(function()
      if windows.isValidBuf('list') then
        cntUpd = cntUpd + 1

        render.renderList()

        if state.focusId and windows.isValidBuf('panel') then
          local tskSel = co.tsk.get(state.focusId)
          if tskSel then
            if tskSel.status == 'running' then render.renderPanel(state.focusId, state.autoScroll) end
          end
        end
      else
        if state.timer then
          state.timer:stop()
          state.timer = nil
        end
      end
    end)
  )
end

function M.initAutoCmd()
  if state.autoCmdGrp then return end

  state.autoCmdGrp = vim.api.nvim_create_augroup('RazTaskUI', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = state.autoCmdGrp,
    pattern = { 'RazTaskCreated', 'RazTaskStarted', 'RazTaskOutput', 'RazTaskComplete' },
    callback = onAutoCmdTsk,
  })
end

function M.startTimer() startUpdTimer() end

function M.stopTimer()
  if state.timer then
    state.timer:stop()
    state.timer = nil
  end
end

function M.cleanup()
  M.stopTimer()
  if state.autoCmdGrp then
    vim.api.nvim_del_augroup_by_id(state.autoCmdGrp)
    state.autoCmdGrp = nil
  end
end

function M.showTaskPanel(tid, autoFocus)
  local co = require('exer.core')
  co.lg.debug('showTaskPanel called with tid: ' .. tostring(tid), 'Events')

  state.focusId = tid
  -- Always create/update panel buffer for the specific task
  local buf = windows.createPanelBuffer(tid)
  co.lg.debug('Panel buffer created/updated: ' .. tostring(buf), 'Events')

  render.renderPanel(tid, state.autoScroll)
  co.lg.debug('renderPanel called for tid: ' .. tostring(tid), 'Events')

  if autoFocus then windows.focus('panel') end
end

function M.setFocusTask(taskId, forceUpdate) focus(taskId, forceUpdate) end

function M.getFocusTask() return state.focusId end

function M.toggleAutoScroll()
  state.autoScroll = not state.autoScroll
  return state.autoScroll
end

function M.getAutoScroll() return state.autoScroll end

function M.setAutoScroll(enabled) state.autoScroll = enabled end

function M.clearFocus() state.focusId = nil end

return M
