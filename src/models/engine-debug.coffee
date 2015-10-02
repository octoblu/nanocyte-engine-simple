{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
    debug '_transform', envelope
    {nodeId} = envelope.config[envelope.fromNodeId]
    next()

    @push
      flowId: envelope.flowId
      instanceId: envelope.instanceId
      toNodeId: 'engine-output'
      message:
        devices: ['*']
        topic: 'debug'
        payload:
          node: nodeId
          msgType: envelope.msgType
          msg:
            payload:
              envelope.message


module.exports = EngineDebug
