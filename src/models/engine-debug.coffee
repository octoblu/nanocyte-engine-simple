{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-debug')

class EngineDebug extends Transform
  constructor: (options)->
    {@fromNodeId} = options
    super objectMode: true

  _transform: ({config, data, message}, enc, next) =>
    {toNodeId} = config[@fromNodeId]
    @push
      devices: ['*']
      topic: 'debug'
      payload:
        msg: message
        node: toNodeId

    next()

module.exports = EngineDebug
