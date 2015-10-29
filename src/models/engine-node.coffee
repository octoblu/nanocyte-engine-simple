{Readable} = require 'stream'
class EngineNode extends Readable
  constructor: ->
    super objectMode: true
    @reading = false
    @envelopes = []

  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream(envelope)

    envelopeStream.on 'readable', =>
      envelope = envelopeStream.read()
      return @envelopes.push envelope unless @reading
      @reading = @push envelope

    envelopeStream.write envelope.message

  _getEnvelopeStream: =>
    throw new Error '_getEnvelopeStream is not implemented'

  _read: =>
    return @reading = true unless @envelopes.length > 0
    while (envelope = @envelopes.pop())
      console.log "pushing envelope"
      return unless @push envelope

module.exports = EngineNode
