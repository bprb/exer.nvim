local M = {}

local co = require('exer.core')
local toml = co.psr.toml

-- local function trim(s) return s:match('^%s*(.-)%s*$') end

-- parse [[apps]] or [[exer.apps]] Array of Tables format
function M.parseAppsArrayOfTables(cnt)
  if not cnt or cnt == '' then return {} end

  local apps = toml.parseArrayOfTables(cnt, 'apps')
  local exerApps = toml.parseArrayOfTables(cnt, 'exer.apps')

  local result = {}
  for _, app in ipairs(apps) do
    result[#result + 1] = app
  end
  for _, app in ipairs(exerApps) do
    result[#result + 1] = app
  end

  return result
end

-- parse apps = [] Inline Array format
function M.parseAppsInlineArray(cnt)
  if not cnt or cnt == '' then return {} end

  local rst = toml.parseArray(cnt, 'apps')
  return rst.apps or {}
end

-- parse all apps (merge both formats)
function M.parseApps(cnt)
  if not cnt or cnt == '' then return {} end

  local apps = {}

  -- parse [[apps]] format
  local arrayOfTablesApps = M.parseAppsArrayOfTables(cnt)
  vim.list_extend(apps, arrayOfTablesApps)

  -- Parse apps = [] format
  local inlineArrayApps = M.parseAppsInlineArray(cnt)
  vim.list_extend(apps, inlineArrayApps)

  return apps
end

-- Parse complete [exer] block
function M.parseExer(cnt)
  if not cnt or cnt == '' then return nil end

  local rst = { acts = {}, apps = {} }

  -- 找到 [exer] 區塊
  local exerStart = cnt:find('%[exer%]')
  if not exerStart then
    -- If no [exer] block found, try to parse global format
    local actsRst = toml.parseArray(cnt, 'acts')
    local exerActsRst = toml.parseArrayOfTables(cnt, 'exer.acts')

    rst.acts = actsRst.acts or {}
    for _, act in ipairs(exerActsRst) do
      rst.acts[#rst.acts + 1] = act
    end

    -- Parse apps
    rst.apps = M.parseApps(cnt)

    return rst
  end

  -- Extract content after [exer] block
  local exerCnt = cnt:sub(exerStart)

  -- Parse acts array and [[exer.acts]]
  local actsRst = toml.parseArray(exerCnt, 'acts')
  local exerActsRst = toml.parseArrayOfTables(exerCnt, 'exer.acts')

  rst.acts = actsRst.acts or {}
  for _, act in ipairs(exerActsRst) do
    rst.acts[#rst.acts + 1] = act
  end

  -- Parse apps
  rst.apps = M.parseApps(exerCnt)

  return rst
end

-- Parse JSON format
function M.parseJson(cnt)
  if not cnt or cnt == '' then return nil end

  local ok, json = pcall(co.psr.json.decode, cnt)
  if not ok or not json then return nil end

  local rst = { acts = {}, apps = {} }

  -- Parse exer section
  if json.exer then
    rst.acts = json.exer.acts or {}
    rst.apps = json.exer.apps or {}
  end

  -- Support root-level acts and apps for simple cases
  if json.acts and not json.exer then rst.acts = json.acts end
  if json.apps and not json.exer then rst.apps = json.apps end

  return rst
end

-- Main parse function
function M.parse(cnt, fileType)
  if fileType == 'json' then
    return M.parseJson(cnt)
  else
    return M.parseExer(cnt)
  end
end

return M
