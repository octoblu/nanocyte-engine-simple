debugStream = require('debug-stream')('nanocyte-engine-simple:engine-pulse-node')
class EnginePulseNode
  constructor: (dependencies) ->
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EnginePulse, @DatastoreCheckKeyStream, @EngineBatch} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EnginePulse ?= require './engine-pulse'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineBatch ?= require './engine-batch'

  message: ({metadata, message}) =>
    inputStream = debugStream 'in'
    outputStream = debugStream 'out'

    inputStream
      .pipe new @DatastoreCheckKeyStream metadata
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EnginePulse metadata
      .pipe new @EngineBatch metadata
      .pipe new @NanocyteToEngineStream metadata
      .pipe outputStream

    inputStream.write message

    outputStream

module.exports = EnginePulseNode
