debugStream = require('debug-stream')('nanocyte-engine-simple:engine-debug-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineDebugNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineDebug, @DatastoreCheckKeyStream} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineDebug ?= require './engine-debug'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @DatastoreCheckKeyStream metadata
      new @EngineToNanocyteStream metadata
      new @EngineDebug metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineDebugNode
