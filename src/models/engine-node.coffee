{Readable} = require 'stream'
_ = require 'lodash'

class EngineNode extends Readable
  constructor: ->
    super objectMode: true
    @reading = false
    @envelopes = []

  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream(envelope)

    envelopeStream.on 'error', (error) =>
      errorMetadata =
        fromNodeId: envelope.metadata.fromNodeId
        toNodeId: 'engine-output'
        msgType: 'error'

      errorEnvelope =
        metadata: _.extend {}, envelope.metadata, errorMetadata
        message:
          message: error.message
          msgType: 'error'
                
      @envelopes.push errorEnvelope
      @readIfAvailable() if @reading

    envelopeStream.on 'readable', =>
      newEnvelope = envelopeStream.read()
      @envelopes.push newEnvelope
      @readIfAvailable() if @reading


    envelopeStream.write envelope.message
    @

  _getEnvelopeStream: =>
    throw new Error '_getEnvelopeStream is not implemented'

  _read: =>
    @reading = true
    @readIfAvailable()

  readIfAvailable: =>
    while (@reading && @envelopes.length)
      envelope = @envelopes.pop()
      @reading = @push envelope

module.exports = EngineNode
