{Transform} = require 'stream'

class EngineDebug extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
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
          msg:
            payload:
              envelope.message


module.exports = EngineDebug
