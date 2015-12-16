{Readable, PassThrough} = require 'stream'
_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-node')

class EngineNode
  constructor: (options, dependencies={})->
    {@messageCounter} = dependencies
    @stream = new PassThrough objectMode: true

  sendEnvelope: (envelope, callback=->) =>
    @messageCounter.add()
    envelopeStream = @_getEnvelopeStream envelope
    envelopeStream.on 'error', (error) => @stream.emit 'error', error
    envelopeStream.pipe @stream
    @stream.on 'finish', => envelopeStream.end()

    debug "enginenode is writing", envelope.message
    envelopeStream.write envelope.message, =>
      @messageCounter.subtract()
      callback()

    return @stream

module.exports = EngineNode
