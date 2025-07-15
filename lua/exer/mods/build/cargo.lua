local M = {}

--========================================================================
-- private
--========================================================================
local co = require('exer.core')

--========================================================================
-- Detect
--========================================================================
function M.detect(pathWorkDir) return co.io.fileExists(pathWorkDir .. '/Cargo.toml') end

--========================================================================
-- Opts
--========================================================================
function M.getOpts(pathWorkDir, pathFile, fileType)
  if not M.detect(pathWorkDir) then return {} end

  local opts = require('exer.picker.opts').new()

  opts:addMod('Build project', 'cargo:build', 'cargo', nil, 'cargo build')
  opts:addMod('Build release', 'cargo:build_release', 'cargo', nil, 'cargo build --release')
  opts:addMod('Run project', 'cargo:run', 'cargo', nil, 'cargo run')
  opts:addMod('Run release', 'cargo:run_release', 'cargo', nil, 'cargo run --release')
  opts:addMod('Test project', 'cargo:test', 'cargo', nil, 'cargo test')
  opts:addMod('Check project', 'cargo:check', 'cargo', nil, 'cargo check')
  opts:addMod('Clean project', 'cargo:clean', 'cargo', nil, 'cargo clean')
  opts:addMod('Update dependencies', 'cargo:update', 'cargo', nil, 'cargo update')
  opts:addMod('Format code', 'cargo:fmt', 'cargo', nil, 'cargo fmt')
  opts:addMod('Lint code', 'cargo:clippy', 'cargo', nil, 'cargo clippy')
  opts:addMod('Install crate', 'cargo:install', 'cargo', nil, 'cargo install <name>')
  opts:addMod('Install local', 'cargo:install_local', 'cargo', nil, 'cargo install --path .')

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

  if option == 'cargo:build' then
    name = 'Cargo: Build'
    cmd = 'cargo build'
  elseif option == 'cargo:build_release' then
    name = 'Cargo: Build (Release)'
    cmd = 'cargo build --release'
  elseif option == 'cargo:run' then
    name = 'Cargo: Run'
    cmd = 'cargo run'
  elseif option == 'cargo:run_release' then
    name = 'Cargo: Run (Release)'
    cmd = 'cargo run --release'
  elseif option == 'cargo:test' then
    name = 'Cargo: Test'
    cmd = 'cargo test'
  elseif option == 'cargo:check' then
    name = 'Cargo: Check'
    cmd = 'cargo check'
  elseif option == 'cargo:clean' then
    name = 'Cargo: Clean'
    cmd = 'cargo clean'
  elseif option == 'cargo:update' then
    name = 'Cargo: Update'
    cmd = 'cargo update'
  elseif option == 'cargo:fmt' then
    name = 'Cargo: Format'
    cmd = 'cargo fmt'
  elseif option == 'cargo:clippy' then
    name = 'Cargo: Clippy'
    cmd = 'cargo clippy'
  elseif option == 'cargo:install' then
    name = 'Cargo: Install'
    local crateName = vim.fn.input('Crate name: ')
    if crateName == '' then
      co.utils.msg('No crate name provided', vim.log.levels.ERROR)
      return
    end
    cmd = 'cargo install ' .. crateName
  elseif option == 'cargo:install_local' then
    name = 'Cargo: Install (Local)'
    cmd = 'cargo install --path .'
  else
    co.utils.msg('Unknown Cargo option: ' .. option, vim.log.levels.ERROR)
    return
  end

  co.runner.run({
    name = name,
    cmds = co.cmd.new():cd(pathWorkDir):add(cmd),
  })
end

--========================================================================
return M
