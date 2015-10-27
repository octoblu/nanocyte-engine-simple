_ = require 'lodash'
colors = require 'colors'
messages = require(process.argv[2])

lastTime = undefined

printMessage = (message) ->
  debug = message.debugInfo
  meta = message.metadata

  lastTime = debug.timestamp unless lastTime?
  timeDiff = debug.timestamp - lastTime
  lastTime = debug.timestamp

  messageString = JSON.stringify message.message
  "[#{colors.yellow meta.transactionId}] " +
  "#{debug.fromNode.config.name || meta.fromNodeId} #{colors.green debug.nanocyteType} #{colors.gray debug.fromNode.config.type} : " +
  "--> " +
  "#{debug.toNode.config.name || meta.toNodeId} (#{debug.toNode.config.type})" +
  " #{colors.green messageString}"

_.each messages, (message) =>
  console.log printMessage message
