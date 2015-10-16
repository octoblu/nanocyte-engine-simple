{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@nodeId} = options
    super objectMode: true

  _transform: (message, enc, next) =>
    @push
      metadata:
        toNodeId: 'engine-output'
      message:
        devices: ['*']
        topic: 'pulse'
        payload:
          node: @nodeId
    next()

module.exports = EnginePulse
