{Readable} = require 'stream'
_ = require 'lodash'

class EngineNode
  message: (envelope) =>
    envelopeStream = @_getEnvelopeStream envelope
    envelopeStream.write envelope.message

    return envelopeStream

module.exports = EngineNode
