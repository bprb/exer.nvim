local M = {}

local Keys = {
  checkFile = 'ts:checkFile',
  compileFile = 'ts:compileFile',
  runTsNode = 'ts:runTsNode',
  checkProj = 'ts:checkProj',
  buildProj = 'ts:buildProj',
}

--========================================================================
-- public define
--========================================================================
-- Language modules use fileTypes instead of detect() for matching
M.fileTypes = { 'typescript', 'typescriptreact' }

--========================================================================
-- private
--========================================================================
local co = require('exer.core')

--========================================================================
-- Opts
--========================================================================
function M.getOpts(pathWorkDir, pathFile, fileType)
  local opts = require('exer.picker.opts').new()

  if pathFile and pathFile:match('%.tsx?$') then
    opts:addMod('Check file syntax', Keys.checkFile, 'typescript', 'TS', 'npx tsc <file> --noEmit')
    opts:addMod('Compile file', Keys.compileFile, 'typescript', 'TS', 'npx tsc <file>')
    opts:addMod('Run with ts-node', Keys.runTsNode, 'typescript', 'TS', 'ts-node <file>')
  end

  if co.io.fileExists(pathWorkDir .. '/tsconfig.json') then
    opts:addMod('Check project', Keys.checkProj, 'typescript', 'TS', 'npx tsc --noEmit')
    opts:addMod('Build project', Keys.buildProj, 'typescript', 'TS', 'npx tsc')
  end

  return opts:build()
end

--========================================================================
-- Acts
--========================================================================
function M.runAct(dst, pathWorkDir, pathFile)
  local filename = vim.fn.fnamemodify(pathFile, ':t')

  if dst == Keys.checkFile then
    co.runner.run({
      name = 'Check "' .. filename .. '"',
      cmds = co.cmd.new():add('npx tsc "' .. pathFile .. '" --noEmit'),
    })
  elseif dst == Keys.compileFile then
    co.runner.run({
      name = 'Compile "' .. filename .. '"',
      cmds = co.cmd.new():add('npx tsc "' .. pathFile .. '"'),
    })
  elseif dst == Keys.runTsNode then
    co.runner.run({
      name = 'Run "' .. filename .. '" with ts-node',
      cmds = co.cmd.new():add('ts-node "' .. pathFile .. '"'),
    })
  elseif dst == Keys.checkProj then
    co.runner.run({
      name = 'Check project',
      cmds = co.cmd.new():cd(pathWorkDir):add('npx tsc --noEmit'),
    })
  elseif dst == Keys.buildProj then
    co.runner.run({
      name = 'Build project',
      cmds = co.cmd.new():cd(pathWorkDir):add('npx tsc'),
    })
  end
end

return M
