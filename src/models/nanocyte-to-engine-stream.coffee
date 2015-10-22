_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:nanocyte-to-engine-stream')
{Transform} = require 'stream'

class NanocyteToEngineStream extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    @metadata = metadata

  _transform: (message, enc, next) =>
    @push
      message: message
      metadata: @metadata        

    next()

module.exports = NanocyteToEngineStream
