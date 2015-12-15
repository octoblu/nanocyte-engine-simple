EngineOutput = require '../../src/models/engine-output'
async = require 'async'
_ = require 'lodash'

class EngineOutputFactory

  @createStreamEngineOutput: (outputStream) ->

    class StreamEngineOutput extends EngineOutput
      _finished: (next) =>
        @push null
        next()

      _transform: (envelope, enc, next) =>
        return @_finished(next) unless outputStream?
        {metadata,message} = envelope
        messages = message?.payload?.messages if message?.topic == 'message-batch'
        async.each messages or [message], (message, callback) =>
          outputStream.write _.merge({},{@metadata},{metadata},{message}), enc, callback
        , => @_finished(next)

module.exports = EngineOutputFactory
