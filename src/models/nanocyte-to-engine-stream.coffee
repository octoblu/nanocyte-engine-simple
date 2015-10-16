_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:nanocyte-to-engine-stream')
{Transform} = require 'stream'

class NanocyteToEngineStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@nodeId} = options

  _transform: (message, enc, next) =>
    @push
      message: message
      metadata:
        fromNodeId: @nodeId

    next()

module.exports = NanocyteToEngineStream
