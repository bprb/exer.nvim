local M = {}

function M.processApps(apps, _)
  if not apps or #apps == 0 then return {} end

  local acts = {}
  local co = require('exer.core')

  for _, app in ipairs(apps) do
    if not app or type(app) ~= 'table' then
      co.lg.debug('Skipping invalid app: not a table', 'Tasks')
      goto continue
    end

    if not app.name then
      co.lg.debug('Skipping app without name', 'Tasks')
      goto continue
    end

    -- Only support custom run commands now
    if app.run_cmd then
      table.insert(acts, {
        id = string.format('run_%s', app.name:gsub('%s+', '_')),
        name = string.format('[Run] %s', app.name),
        cmd = app.run_cmd,
        type = 'app_run',
      })
      co.lg.debug(string.format('Added custom run command for app: %s', app.name), 'Tasks')
    else
      co.lg.debug(string.format('Skipping app without run_cmd: %s', app.name), 'Tasks')
    end

    ::continue::
  end

  return acts
end

return M
