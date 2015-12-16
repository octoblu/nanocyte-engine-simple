EngineOutput = require '../../src/models/engine-output'
async = require 'async'
_ = require 'lodash'

class EngineOutputFactory

  @createStreamEngineOutput: (outputStream) ->

    class StreamEngineOutput extends EngineOutput
      _done: (next, error) =>
        @push null
        next(error) if next?

      _transform: (envelope, enc, next) =>
        return @_done(next) unless outputStream?
        {metadata,message} = envelope
        messages = message?.payload?.messages if message?.topic == 'message-batch'
        async.each messages or [message], (message, callback) =>
          outputStream.write _.merge({},{@metadata},{metadata},{message}), enc, callback
        , => @_done(next)

module.exports = EngineOutputFactory
