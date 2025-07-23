local M = {}

local psr = require('exer.proj.parser')
local fnd = require('exer.proj.find')
local vad = require('exer.proj.valid')
local tsk = require('exer.proj.tasks')
local var = require('exer.proj.vars')

local cache = {}

function M.load()
  local cfgPath = M.findCfg()
  if not cfgPath then
    require('exer.core').lg.debug('[proj] No config file found')
    return { acts = {}, apps = {} }
  end

  require('exer.core').lg.debug('[proj] Loading config from: ' .. cfgPath)
  if cache[cfgPath] then
    require('exer.core').lg.debug('[proj] Using cached config')
    return cache[cfgPath]
  end

  local cnt = vim.fn.readfile(cfgPath)
  if not cnt or #cnt == 0 then return { acts = {}, apps = {} } end

  local fileCnt = table.concat(cnt, '\n')
  local cfg

  if cfgPath:match('%.editorconfig$') then
    local co = require('exer.core')
    co.lg.debug('[proj] Processing .editorconfig file')
    local editorconfig = co.psr.editorconfig
    local exerCnt, sectionType = editorconfig.extractExerSection(fileCnt)
    if exerCnt then
      co.lg.debug('[proj] Found exer content, section type: ' .. (sectionType or 'none'))
      -- If it's INI format [exer.acts], convert to TOML
      if sectionType == 'exer_acts' then
        co.lg.debug('[proj] Converting INI format to TOML')
        local convertedToml = editorconfig.convertIniToToml(exerCnt)
        if convertedToml then
          co.lg.debug('[proj] Converted TOML: ' .. convertedToml)
          cfg = M.parse(convertedToml)
        else
          co.lg.debug('[proj] Failed to convert INI to TOML')
        end
      else
        -- Parse as regular TOML
        co.lg.debug('[proj] Parsing as regular TOML')
        cfg = M.parse(exerCnt)
      end
    else
      co.lg.debug('[proj] No exer content found in .editorconfig')
    end
  else
    local fileType = cfgPath:match('%.json$') and 'json' or 'toml'
    cfg = M.parse(fileCnt, fileType)
  end

  if not cfg then return { acts = {}, apps = {} } end

  if not M.validate(cfg) then return { acts = {}, apps = {} } end

  cache[cfgPath] = cfg
  return cfg
end

function M.findCfg() return fnd.find() end

function M.parse(cnt, fileType) return psr.parse(cnt, fileType) end

function M.filterActs(acts, ft)
  if not acts or #acts == 0 then return {} end

  local flt = {}
  for _, act in ipairs(acts) do
    if not act.when then
      table.insert(flt, act)
    elseif type(act.when) == 'string' then
      if act.when == ft then table.insert(flt, act) end
    elseif type(act.when) == 'table' then
      for _, whenFt in ipairs(act.when) do
        if whenFt == ft then
          table.insert(flt, act)
          break
        end
      end
    end
  end

  return flt
end

function M.expandVars(cmd) return var.expandVars(cmd) end

function M.validate(cfg) return vad.validate(cfg) end

function M.processApps(apps, ft) return tsk.processApps(apps, ft) end

function M.getActs(ft)
  local cfg = M.load()
  if not cfg then return {} end

  local acts = {}

  -- Add original acts
  if cfg.acts then
    local filteredActs = M.filterActs(cfg.acts, ft)
    vim.list_extend(acts, filteredActs)
  end

  -- Process apps, convert to acts
  if cfg.apps then
    local appActs = tsk.processApps(cfg.apps, ft)
    vim.list_extend(acts, appActs)
  end

  return acts
end

function M.clearCache() cache = {} end

return M
