{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    @push
      devices: ['*']
      topic: 'pulse'
      payload:
        node: config[@fromNodeId]?.toNodeId

    @push null

    next()

module.exports = EnginePulse
