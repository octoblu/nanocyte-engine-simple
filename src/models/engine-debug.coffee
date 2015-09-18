{Transform} = require 'stream'

class EngineDebug extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
    {nodeId} = envelope.config[envelope.fromNodeId]
    next()

    @push
      devices: [envelope.flowId]
      topic: 'debug'
      payload:
        node: nodeId
        msg:
          payload:
            envelope.message


module.exports = EngineDebug
