_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-ping')

class EnginePing extends Transform
  constructor: (metadata={})->
    {@fromNodeId} = metadata
    super objectMode: true

  getPingMessage: ({config,message}) =>
    {nodeId} = config?[@fromNodeId] or {nodeId:@fromNodeId}
    newMessage =
      devices: [message.fromUuid]
      topic: 'pong'
      payload:
        node: nodeId

    _.extend newMessage.payload, message.payload
    return newMessage

  _transform: (envelope, enc, next) =>
    message = @getPingMessage envelope
    debug "sending message", message
    @push message
    @push null
    next()

module.exports = EnginePing
