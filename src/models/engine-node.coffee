{Readable, PassThrough} = require 'stream'
_ = require 'lodash'

class EngineNode
  constructor: ->
    @stream = new PassThrough objectMode: true

  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream envelope
    envelopeStream.pipe @stream
    envelopeStream.write envelope.message

    return @stream

module.exports = EngineNode
