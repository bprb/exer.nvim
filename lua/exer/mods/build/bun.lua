local M = {}

local Keys = {
  install = 'bun:install',
  runFile = 'bun:runFile',
  testAll = 'bun:testAll',
  testFile = 'bun:testFile',
  testCursor = 'bun:testCursor',
}

--========================================================================
-- private
--========================================================================
local co = require('exer.core')

local function isTestFile(pathFile)
  if not pathFile then return false end

  local filename = vim.fn.fnamemodify(pathFile, ':t')
  local pathDir = vim.fn.fnamemodify(pathFile, ':h')

  -- Check filename patterns
  if filename:match('%.test%.') or filename:match('%.spec%.') then return true end
  if filename:match('^test_') or filename:match('_test%.') then return true end
  if pathDir:match('__tests__') then return true end

  -- Check file content for test keywords
  if co.io.fileExists(pathFile) then
    local content = vim.fn.readfile(pathFile, '', 100) -- Read first 100 lines
    local contentStr = table.concat(content, '\n')

    -- Check for test-related imports or functions
    if contentStr:match('from%s+["\']bun:test["\']') then return true end
    if contentStr:match('describe%s*%(') or contentStr:match('test%s*%(') or contentStr:match('it%s*%(') then return true end
  end

  return false
end

--========================================================================
-- Detect
--========================================================================
function M.detect(pathWorkDir)
  local bunLockb = pathWorkDir .. co.utils.osPath('/bun.lockb')
  local bunfigToml = pathWorkDir .. co.utils.osPath('/bunfig.toml')

  co.lg.debug('Bun detect called with pathWorkDir: ' .. pathWorkDir, 'Bun')
  co.lg.debug('Bun detect checking: ' .. bunLockb .. ' and ' .. bunfigToml, 'Bun')

  local hasBunFiles = co.io.fileExists(bunLockb) or co.io.fileExists(bunfigToml)

  co.lg.debug('Bun project detected: ' .. tostring(hasBunFiles), 'Bun')

  return hasBunFiles
end

--========================================================================
-- Opts
--========================================================================
function M.getOpts(pathWorkDir, pathFile, fileType)
  local pathPkg = pathWorkDir .. co.utils.osPath('/package.json')
  local jsonPkg = co.io.readJson(pathPkg)

  local opts = require('exer.picker.opts').new()

  -- Install dependencies
  if jsonPkg then
    opts:addMod('bun install', Keys.install, 'bun', nil, 'bun install')

    -- Add package.json scripts
    local scripts = jsonPkg.scripts
    if scripts then
      for script, _ in pairs(scripts) do
        local key = 'bun:script:' .. script
        opts:addMod('bun run ' .. script, key, 'bun', nil, 'bun run ' .. script)
      end
    end
  end

  -- Run file option for JavaScript/TypeScript files
  if pathFile and (pathFile:match('%.js$') or pathFile:match('%.mjs$') or pathFile:match('%.ts$') or pathFile:match('%.tsx$') or pathFile:match('%.jsx$')) then
    opts:addMod('Run file (Bun)', Keys.runFile, 'bun', nil, 'bun run <file>')

    -- Test options if it's a test file
    if isTestFile(pathFile) then
      opts:addMod('Test file (Bun)', Keys.testFile, 'bun', nil, 'bun test <file>')
      opts:addMod('Test at cursor (Bun)', Keys.testCursor, 'bun', nil, 'bun test <file> -t <test>')
    end
  end

  -- Always show test all option
  opts:addMod('Test all (Bun)', Keys.testAll, 'bun', nil, 'bun test')

  return opts:build()
end

--========================================================================
-- Acts
--========================================================================
function M.runAct(option, pathWorkDir, pathFile)
  if not option or option == '' then
    co.utils.msg('No command specified', vim.log.levels.ERROR)
    return
  end

  local name = ''
  local cmd = ''

  if option == Keys.install then
    name = 'Bun: Install Dependencies'
    cmd = 'bun install'
  elseif option == Keys.runFile then
    local filename = vim.fn.fnamemodify(pathFile, ':t')
    name = 'Run "' .. filename .. '" (Bun)'
    cmd = 'bun run "' .. pathFile .. '"'
  elseif option == Keys.testAll then
    name = 'Bun: Test All'
    cmd = 'bun test'
  elseif option == Keys.testFile then
    local filename = vim.fn.fnamemodify(pathFile, ':t')
    name = 'Test "' .. filename .. '" (Bun)'
    cmd = 'bun test "' .. pathFile .. '"'
  elseif option == Keys.testCursor then
    name = 'Bun: Test at Cursor'
    local tsUtils = co.psr.treesitter
    local testName = tsUtils.getTestNameAtCursor()
    if testName then
      cmd = 'bun test "' .. pathFile .. '" -t "' .. testName .. '"'
    else
      cmd = 'bun test "' .. pathFile .. '"'
    end
  elseif option:match('^bun:script:(.+)$') then
    local script = option:match('^bun:script:(.+)$')
    name = 'Bun: Run ' .. script
    cmd = 'bun run ' .. script
  else
    co.utils.msg('Unknown Bun option: ' .. option, vim.log.levels.ERROR)
    return
  end

  co.runner.run({
    name = name,
    cmds = co.cmd.new():cd(pathWorkDir):add(cmd),
  })
end

return M
