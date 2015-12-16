{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    {nodeId} = config[@fromNodeId]
    @push
      devices: ['*']
      topic: 'pulse'
      payload:
        node: nodeId

    @push null
    next() if next?

module.exports = EnginePulse
