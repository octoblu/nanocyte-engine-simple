{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: (metadata)->
    {@fromNodeId, @msgType} = metadata
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    debug "incoming message from #{@fromNodeId}", config, data, message
    return @push null unless config?[@fromNodeId]?
    {nodeId} = config[@fromNodeId]

    message =
      devices: ['*']
      topic: 'debug'
      payload:
        msg: message
        node: nodeId
        msgType: @msgType

    debug "sending message", message

    @push message
    @push null
    next()

module.exports = EngineDebug
