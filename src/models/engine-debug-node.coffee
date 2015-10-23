debug = require('debug')('nanocyte-engine-simple:engine-debug-node')
debugStream = require('debug-stream')('nanocyte-engine-simple:engine-debug-node')
class EngineDebugNode
  constructor: (dependencies={}) ->
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineDebug, @DatastoreCheckKeyStream, @EngineBatch} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineDebug ?= require './engine-debug'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineBatch ?= require './engine-batch'

  message: ({metadata, message}) =>
    inputStream = debugStream 'in'
    outputStream = debugStream 'out'

    inputStream
      .pipe new @DatastoreCheckKeyStream metadata
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineDebug metadata
      .pipe new @EngineBatch metadata
      .pipe new @NanocyteToEngineStream metadata
      .pipe outputStream

    inputStream.write message

    outputStream

module.exports = EngineDebugNode
