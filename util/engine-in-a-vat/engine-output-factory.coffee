EngineOutput = require '../../src/models/engine-output'
async = require 'async'

class EngineOutputFactory

  @createStreamEngineOutput: (outputStream) ->

    class StreamEngineOutput extends EngineOutput
      _finished: (next) =>
        @push null
        next()

      _transform: ({config, message}, enc, next) =>
        return @_finished(next) unless outputStream?
        messages = message?.payload?.messages if message?.topic == 'message-batch'
        async.each messages or [message], (message, callback) =>
          outputStream.write {@metadata,config,message}, enc, callback
        , => @_finished(next)

module.exports = EngineOutputFactory
