{Readable, PassThrough} = require 'stream'
_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-node')

class EngineNode
  constructor: ->
    @stream = new PassThrough objectMode: true

  sendEnvelope: (envelope) =>
    envelopeStream = @_getEnvelopeStream envelope
    envelopeStream.on 'error', (error) => @stream.emit 'error', error

    envelopeStream.pipe @stream
    debug "enginenode is writing", envelope.message
    envelopeStream.write envelope.message

    return @stream

module.exports = EngineNode
