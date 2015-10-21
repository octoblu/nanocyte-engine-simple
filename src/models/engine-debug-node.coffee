{Writable} = require 'stream'
class EngineDebugNode extends Writable
  constructor: (dependencies) ->
    super objectMode: true

    {@EngineToNanocyteStream, @EngineDebug, @DatastoreCheckKeyStream, @EngineOutput} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @EngineDebug ?= require './engine-debug'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineOutput ?= require './engine-output'
  message: ({metadata, message}) =>
    engineToNanocyteStream = new @EngineToNanocyteStream metadata

module.exports = EngineDebugNode
