debugStream = require('debug-stream')('nanocyte-engine-simple:engine-pulse-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EnginePulseNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EnginePulse, @DatastoreCheckKeyStream} = @dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EnginePulse ?= require './engine-pulse'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'

  _getEnvelopeStream: ({metadata}) =>
    combine.obj(
      debugStream 'in'
      new @DatastoreCheckKeyStream metadata, @dependencies
      new @EngineToNanocyteStream metadata, @dependencies
      new @EnginePulse metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EnginePulseNode
