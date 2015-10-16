{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@fromNodeId} = options
    super objectMode: true

  _transform: (message, enc, next) =>
    @push
      devices: ['*']
      topic: 'pulse'
      payload:
        node: @fromNodeId

    next()

module.exports = EnginePulse
