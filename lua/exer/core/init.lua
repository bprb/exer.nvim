return {
  cmd = require('exer.core.cmd'),
  io = require('exer.core.io'),
  lg = require('exer.core.lg'),
  picker = require('exer.picker'),
  runner = require('exer.core.runner'),
  tsk = require('exer.core.tsk'),
  utils = require('exer.core.utils'),
  psr = {
    toml = require('exer.core.psr.toml'),
    treesitter = require('exer.core.psr.treesitter'),
    editorconfig = require('exer.core.psr.editorconfig'),
    json = require('exer.core.psr.json'),
  },
}
