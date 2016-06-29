{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-node')

class EngineNode
  constructor: (options, dependencies={})->
    @stream = new PassThrough objectMode: true

  sendEnvelope: (envelope, callback=->) =>
    envelopeStream = @_getEnvelopeStream envelope
    envelopeStream.on 'error', (error) => @stream.emit 'error', error
    envelopeStream.pipe @stream
    @stream.on 'finish', => envelopeStream.end()

    debug "enginenode is writing", envelope.message
    try
      envelopeStream.write envelope.message, callback
    catch error
      console.error 'envelopeStream.write error:', JSON.stringify(envelope)
      throw error

    return @stream

module.exports = EngineNode
