debugStream = require('debug-stream')('nanocyte-engine-simple:engine-data-node')
class EngineDataNode
  constructor: (dependencies={}) ->
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineData} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineData ?= require './engine-data'

  message: ({metadata, message}) =>
    inputStream = debugStream 'in'
    outputStream = debugStream 'out'

    inputStream
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineData metadata
      .pipe new @NanocyteToEngineStream metadata
      .pipe outputStream

    inputStream.write message

    outputStream

module.exports = EngineDataNode
