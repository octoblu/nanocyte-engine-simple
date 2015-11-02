{Readable} = require 'stream'
_ = require 'lodash'

class EngineNode extends Readable
  constructor: ->
    super objectMode: true
    @reading = false
    @envelopes = []

  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream(envelope)
    @readIfAvailable() if @reading

    envelopeStream.on 'error', (error) => @emit 'error', error

    envelopeStream.on 'readable', =>
      newEnvelope = envelopeStream.read()
      @envelopes.push newEnvelope
      @readIfAvailable() if @reading

    envelopeStream.write envelope.message

    return envelopeStream

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
