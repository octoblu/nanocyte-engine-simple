debugStream = require('debug-stream')('nanocyte-engine-simple:nanocyte-node-wrapper')

class NanocyteNodeWrapper

  @wrap: (NanocyteClass) ->
    throw new Error 'NanocyteClass is undefined' unless NanocyteClass?

    class WrappedNanocyteClass
      constructor: (dependencies={}) ->
        {@EngineToNanocyteStream, @NanocyteToEngineStream,@ChristacheioStream} = dependencies

        @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
        @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
        @ChristacheioStream ?= require './christacheio-stream'

      message: ({metadata, message}) =>
        inputStream = debugStream 'in'
        outputStream = debugStream 'out'

        inputStream
          .pipe new @EngineToNanocyteStream metadata
          .pipe new @ChristacheioStream metadata
          .pipe new NanocyteClass metadata
          .pipe new @NanocyteToEngineStream metadata
          .pipe outputStream

        inputStream.write message

        outputStream


module.exports = NanocyteNodeWrapper
