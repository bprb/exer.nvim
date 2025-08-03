describe('Space in ID normalization', function()
  local ut = require('tests.unitester')
  ut.setup()

  local proj = require('exer.proj')
  local config = require('exer.config')

  ut.itEnv('normalizes spaces in act.id to underscores', {
    cwd = '/test/project',
    currentFile = 'test.py',
    files = {
      ['exer.toml'] = [[
[exer]
acts = [
  { id = "copy to 387mods", cmd = "cp test.py mods/", desc = "Copy to mods folder" },
  { id = "build and run", cmd = "python ${file}", desc = "Build and run the file" }
]
      ]],
      ['test.py'] = 'print("hello")',
    },
  }, function()
    local acts = proj.getActs('python')
    ut.assert.are.equal(2, #acts)
    ut.assert.are.equal('copy_to_387mods', acts[1].id)
    ut.assert.are.equal('build_and_run', acts[2].id)
    ut.assert.are.equal('Copy to mods folder', acts[1].desc)
    ut.assert.are.equal('Build and run the file', acts[2].desc)
  end)

  ut.itEnv('normalizes spaces in app-generated IDs', {
    cwd = '/test/project',
    currentFile = 'test.py',
    files = {
      ['exer.toml'] = '[exer]\n' ..
        '[[apps]]\n' ..
        'name = "My Test App"\n' ..
        'entry = "main.py"\n' ..
        'output = "dist/app"\n' ..
        'run_cmd = "python main.py"\n',
      ['test.py'] = 'print("hello")',
    },
  }, function()
    local acts = proj.getActs('python')
    ut.assert.are.equal(1, #acts)
    ut.assert.are.equal('run_My_Test_App', acts[1].id)
    ut.assert.are.equal('[Run] My Test App', acts[1].name)
  end)
end)