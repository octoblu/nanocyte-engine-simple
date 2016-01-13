debugStream = require('debug-stream')('nanocyte-engine-simple:engine-ping-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EnginePingNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EnginePing, @DatastoreCheckKeyStream} = @dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EnginePing ?= require './engine-ping'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata, @dependencies
      new @EnginePing metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EnginePingNode
