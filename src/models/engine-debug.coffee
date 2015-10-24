{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: (options)->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    {nodeId} = config[@fromNodeId]
    @push
      devices: ['*']
      topic: 'debug'
      payload:
        msg: message
        node: nodeId

    @push null
    next()

module.exports = EngineDebug
