{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
    debug '_transform', envelope
    {nodeId} = envelope.config[envelope.fromNodeId]

    @push
      flowId: envelope.flowId
      instanceId: envelope.instanceId
      toNodeId: 'engine-output'
      message:
        devices: ['*']
        topic: 'debug'
        payload:
          msgType: envelope.msgType
          msg: envelope.message
          node: nodeId

    next()

module.exports = EngineDebug
