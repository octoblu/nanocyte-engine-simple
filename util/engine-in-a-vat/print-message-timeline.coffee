_ = require 'lodash'
path = require 'path'
messages = require path.join(path.cwd(), process.argv[2])
EngineInAVat = require './engine-in-a-vat'
lastTime = undefined

_.each messages, (message) =>
  console.log EngineInAVat.printMessage message
