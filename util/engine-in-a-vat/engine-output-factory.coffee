EngineOutput = require '../../src/models/engine-output'
async = require 'async'
_ = require 'lodash'

class EngineOutputFactory

  @createStreamEngineOutput: (outputStream) ->

    class StreamEngineOutput extends EngineOutput
      _done: (next, error) =>
        @push null
        next(error) if next?

      _flush: (callback) =>
        console.log 'calling flush EngineOutput!'
        return callback() unless @transforming
        @flushCallback = callback

      _transform: (envelope, enc, next) =>
        console.log 'calling write EngineOutput!'
        return @_done(next) unless outputStream?
        @transforming = true
        {metadata,message} = envelope
        messages = message?.payload?.messages if message?.topic == 'message-batch'
        async.each messages or [message], (message, callback) =>
          outputStream.write _.merge({},{@metadata},{metadata},{message}), enc, callback
        , =>
          @transforming = false
          @flushCallback() if @flushCallback?
          @_done(next)

module.exports = EngineOutputFactory
