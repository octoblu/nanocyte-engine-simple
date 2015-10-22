_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:nanocyte-to-engine-stream')
{Transform} = require 'stream'

class NanocyteToEngineStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@toNodeId} = options

  _transform: (message, enc, next) =>
    @push
      message: message
      metadata:
        fromNodeId: @toNodeId

    next()

module.exports = NanocyteToEngineStream
