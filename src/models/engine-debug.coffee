{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: (metadata={})->
    {@fromNodeId, @msgType} = metadata
    super objectMode: true

  getDebugMessage: ({config,message}) =>
    {nodeId} = config?[@fromNodeId] or {nodeId:@fromNodeId}
    devices: ['*']
    topic: 'debug'
    payload:
      msg: message
      node: nodeId
      msgType: @msgType

  _transform: (envelope, enc, next) =>
    message = @getDebugMessage envelope
    debug "sending message", message
    @push message
    @push null
    next()

module.exports = EngineDebug
