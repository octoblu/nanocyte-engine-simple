{Writable} = require 'stream'
class EngineDebugNode extends Writable
  constructor: (dependencies) ->
    super objectMode: true
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineDebug, @DatastoreCheckKeyStream, @EngineOutput} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineDebug ?= require './engine-debug'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineOutput ?= require './engine-output'

  message: ({metadata, message}) =>
    outputStream = new @NanocyteToEngineStream metadata
    inputStream = new @DatastoreCheckKeyStream metadata
    inputStream
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineDebug metadata
      .pipe outputStream

    inputStream.write message

    outputStream


module.exports = EngineDebugNode
