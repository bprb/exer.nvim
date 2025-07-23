local M = {}

local Keys = {
  compileFile = 'c:compileFile',
  compileAndRun = 'c:compileAndRun',
  runFile = 'c:runFile',
}

--========================================================================
-- public define
--========================================================================
-- Language modules use fileTypes instead of detect() for matching
M.fileTypes = { 'c' }

--========================================================================
-- private
--========================================================================
local co = require('exer.core')

--========================================================================
-- Opts
--========================================================================
function M.getOpts(pathWorkDir, pathFile, fileType)
  local opts = require('exer.picker.opts').new()

  if pathFile and pathFile:match('%.c$') then
    opts:addMod('Compile file', Keys.compileFile, 'c', nil, 'gcc <file> -o <output>')
    opts:addMod('Compile and run', Keys.compileAndRun, 'c', nil, 'gcc <file> -o <output> && ./<output>')

    local execPath = pathFile:gsub('%.c$', '')
    if co.io.fileExists(execPath) then opts:addMod('Run compiled file', Keys.runFile, 'c', nil, './<output>') end
  end

  return opts:build()
end

--========================================================================
-- Acts
--========================================================================
function M.runAct(dst, pathWorkDir, pathFile)
  local filename = vim.fn.fnamemodify(pathFile, ':t')
  local nameNoExt = vim.fn.fnamemodify(pathFile, ':t:r')
  local fullPathNoExt = vim.fn.fnamemodify(pathFile, ':p:r')

  if dst == Keys.compileFile then
    co.runner.run({
      name = 'Compile "' .. filename .. '"',
      cmds = co.cmd.new():add('gcc "' .. pathFile .. '" -o "' .. fullPathNoExt .. '"'),
    })
  elseif dst == Keys.compileAndRun then
    co.runner.run({
      name = 'Compile and run "' .. filename .. '"',
      cmds = co.cmd.new():add('gcc "' .. pathFile .. '" -o "' .. fullPathNoExt .. '"'):add('"' .. fullPathNoExt .. '"'),
    })
  elseif dst == Keys.runFile then
    co.runner.run({
      name = 'Run "' .. nameNoExt .. '"',
      cmds = co.cmd.new():add('"' .. fullPathNoExt .. '"'),
    })
  end
end

return M
