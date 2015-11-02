debugStream = require('debug-stream')('nanocyte-engine-simple:ngine-pulse-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EnginePulseNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EnginePulse, @DatastoreCheckKeyStream, @EngineBatch} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EnginePulse ?= require './engine-pulse'
    @DatastoreCheckKeyStream ?= require './datastore-check-key-stream'
    @EngineBatch ?= require './engine-batch'


  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @DatastoreCheckKeyStream metadata
      new @EngineToNanocyteStream metadata
      new @EnginePulse metadata
      new @EngineBatch metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EnginePulseNode
