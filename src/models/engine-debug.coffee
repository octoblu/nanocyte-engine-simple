{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: (metadata)->
    {@fromNodeId, @msgType} = metadata
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    debug "incoming message:", @fromNodeId, config, data, message
    {nodeId} = config[@fromNodeId]
    debug "nodeId", nodeId

    message =
      devices: ['*']
      topic: 'debug'
      payload:
        msg: message
        node: nodeId
        msgType: @msgType

    @push message
    @push null
    next()

module.exports = EngineDebug
