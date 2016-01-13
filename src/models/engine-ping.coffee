{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-ping')

class EnginePing extends Transform
  constructor: (metadata={})->
    {@fromNodeId, @msgType} = metadata
    super objectMode: true

  getPingMessage: ({config,message}) =>
    {nodeId} = config?[@fromNodeId] or {nodeId:@fromNodeId}
    devices: [message.fromUuid]
    topic: 'pong'
    payload:
      msg: message
      node: nodeId
      msgType: @msgType

  _transform: (envelope, enc, next) =>
    message = @getPingMessage envelope
    debug "sending message", message
    @push message
    @push null
    next()

module.exports = EnginePing
