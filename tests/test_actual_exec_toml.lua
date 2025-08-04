local ut = require('tests.unitester')
ut.setup()

describe('Real exer.toml file parsing', function()
  it('reads and parses the actual exer.toml file', function()
    local psr = require('exer.proj.parser')
    local io = require('exer.core.io')

    -- Try to find exer.toml in different locations
    local exec_file = nil
    local possible_paths = {
      'exer.toml',
      '../exer.toml',
      '../../exer.toml',
      vim.fn.getcwd() .. '/exer.toml',
    }

    for _, path in ipairs(possible_paths) do
      if io.fileExists(path) then
        exec_file = path
        break
      end
    end

    if not exec_file then
      -- Skip test if file not found (common in CI environments)
      print('Info: Skipping test - exer.toml not found in test environment')
      return
    end

    local file_content = vim.fn.readfile(exec_file)
    ut.assert.is_true(#file_content > 0, 'exer.toml should have content')

    local content = table.concat(file_content, '\n')
    local cfg = psr.parse(content)

    ut.assert.is_true(cfg ~= nil, 'should parse exer.toml')
    ut.assert.is_true(cfg.acts ~= nil, 'should have acts')
    ut.assert.is_true(cfg.apps ~= nil, 'should have apps')
    ut.assert.is_true(#cfg.acts > 0, 'should have some acts')
    ut.assert.is_true(#cfg.apps > 0, 'should have some apps')

    local has_lua_run = false
    for _, act in ipairs(cfg.acts) do
      if act.id == 'lua_run' then
        has_lua_run = true
        ut.assert.are.equal('lua ${file}', act.cmd)
        break
      end
    end
    ut.assert.is_true(has_lua_run, 'should have lua_run task')

    local has_hello_world = false
    for _, app in ipairs(cfg.apps) do
      if app.name == 'hello_world' then
        has_hello_world = true
        break
      end
    end
    ut.assert.is_true(has_hello_world, 'should have hello_world app')
  end)
end)
