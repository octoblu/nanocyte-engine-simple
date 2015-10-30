{Readable} = require 'stream'
class EngineNode extends Readable
  constructor: ->
    super objectMode: true
    @reading = false
    @envelopes = []

  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream(envelope)

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
