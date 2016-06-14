{Transform} = require 'stream'

class EnginePulse extends Transform
  constructor: (options={}) ->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    node  = config[@fromNodeId]
    node ?= {}
    {nodeId} =  node
    @push
      devices: ['*']
      topic: 'pulse'
      payload:
        node: nodeId

    @push null
    next() if next?

module.exports = EnginePulse
