describe('Enable builtin mods configuration', function()
  local ut = require('tests.unitester')
  ut.setup()

  local config = require('exer.config')
  local picker = require('exer.picker')
  local mods = require('exer.mods')

  ut.it('should load builtin modules by default', function()
    config.setup({})
    local cfg = config.get()
    ut.assert.are.equal(true, cfg.enable_builtin_mods)
  end)

  ut.it('should respect enable_builtin_mods = false', function()
    config.setup({ enable_builtin_mods = false })
    local cfg = config.get()
    ut.assert.are.equal(false, cfg.enable_builtin_mods)
  end)

  ut.itEnv('should show only project tasks when builtin mods disabled', {
    cwd = '/test/project',
    currentFile = 'test.py',
    config = {
      enable_builtin_mods = false,
    },
    files = {
      ['exer.toml'] = [[
[exer]
acts = [
  { id = "run_project", cmd = "python ${file}", desc = "Project Python Runner" },
  { id = "test_project", cmd = "pytest", desc = "Project Test Runner" }
]
      ]],
      ['test.py'] = 'print("hello")',
    },
  }, function()
    -- Mock the picker to capture what options it would show
    local capturedOpts = nil
    local originalPick = picker.pick
    picker.pick = function(cfg) capturedOpts = cfg.items end

    -- Call picker.show() which loads all options
    picker.show()

    -- Restore original function
    picker.pick = originalPick

    -- Verify only project tasks are shown
    ut.assert.are.equal('table', type(capturedOpts))
    ut.assert.are.equal(2, #capturedOpts)
    ut.assert.are.equal('run_project', capturedOpts[1].value)
    ut.assert.are.equal('test_project', capturedOpts[2].value)
    ut.assert.are.equal('Proj', capturedOpts[1].type)
    ut.assert.are.equal('Proj', capturedOpts[2].type)
  end)

  ut.it('should respect enable_builtin_mods configuration in picker', function()
    -- Test that the configuration properly controls whether builtin modules are loaded
    local originalGetOpts = mods.getOpts
    local getOptsCalled = false

    -- Mock mods.getOpts to track if it's called
    mods.getOpts = function(...)
      getOptsCalled = true
      return {}
    end

    -- Test with enable_builtin_mods = false
    config.setup({ enable_builtin_mods = false })
    local cfg = config.get()

    -- Simulate what picker does
    if cfg.enable_builtin_mods then mods.getOpts('python') end

    ut.assert.are.equal(false, getOptsCalled)

    -- Reset and test with enable_builtin_mods = true
    getOptsCalled = false
    config.setup({ enable_builtin_mods = true })
    cfg = config.get()

    if cfg.enable_builtin_mods then mods.getOpts('python') end

    ut.assert.are.equal(true, getOptsCalled)

    -- Restore original function
    mods.getOpts = originalGetOpts
  end)
end)
