{Writable} = require 'stream'
class EngineDebugNode extends Writable
  constructor: (dependencies) ->
    super objectMode: true
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineDebug, @DatastoreCheckKeyStream, @EngineBatch} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineDebug ?= require './engine-debug'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineBatch ?= require './engine-batch'

  message: ({metadata, message}) =>
    inputStream = new @DatastoreCheckKeyStream metadata
    inputStream.write message

    inputStream
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineDebug metadata
      .pipe new @EngineBatch metadata
      .pipe new @NanocyteToEngineStream metadata

module.exports = EngineDebugNode
