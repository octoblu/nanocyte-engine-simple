debugStream = require('debug-stream')('nanocyte-engine-simple:engine-debug-node')

class NanocyteNodeWrapper

  @wrap: (NanocyteClass) =>

    class WrappedNanocyteClass
      constructor: (dependencies={}) ->
        {@ChristacheioStream} = dependencies
        @ChristacheioStream ?= require './christacheio-stream'

      message: ({metadata, message}) =>
        inputStream = debugStream 'in'
        outputStream = debugStream 'out'

        inputStream
          .pipe new @ChristacheioStream metadata
          .pipe new NanocyteClass metadata
          .pipe outputStream

        inputStream.write message

        outputStream


module.exports = NanocyteNodeWrapper
