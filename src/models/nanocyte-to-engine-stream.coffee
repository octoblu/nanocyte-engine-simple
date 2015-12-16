_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:nanocyte-to-engine-stream')
{Transform} = require 'stream'

class NanocyteToEngineStream extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true

    debug "NanocyteToEngineStream constructed"

    @metadata = _.clone metadata
    @metadata.fromNodeId = @metadata.toNodeId
    delete @metadata.toNodeId

  _done: (next, error) =>
    @push null
    next(error) if next?

  _transform: (message, enc, next) =>
    _.defer =>
      return @_done next unless message?
      @push
        message: message
        metadata: @metadata
      debug "NanocyteToEngineStream sending message", message, "with metadata", @metadata
      next() if next?

module.exports = NanocyteToEngineStream
