{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: ->
    super objectMode: true

  _transform: (envelope, enc, next) =>
    {nodeId} = envelope.config[envelope.fromNodeId]
    next()

    @push
      devices: [envelope.flowId]
      topic: 'pulse'
      payload:
        node: nodeId

module.exports = EnginePulse
