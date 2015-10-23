debugStream = require('debug-stream')('nanocyte-engine-simple:engine-output-node')
class EngineOutputNode
  constructor: (dependencies) ->
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineOutput, @EngineThrottle} = dependencies

    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineOutput ?= require './engine-output'
    @EngineThrottle ?= require './engine-throttle'

  message: ({metadata, message}) =>
    inputStream = debugStream 'in'
    outputStream = debugStream 'out'

    inputStream
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineThrottle metadata
      .pipe new @EngineOutput metadata
      .pipe new @NanocyteToEngineStream metadata
      .pipe outputStream

    inputStream.write message
    outputStream

module.exports = EngineOutputNode
