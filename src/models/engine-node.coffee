{Readable} = require 'stream'
_ = require 'lodash'
Domain       = require 'domain'

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

    domain = Domain.create()

    domain.on 'error', (error) => @push null

    domain.run =>
      @envelopes.push null
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
