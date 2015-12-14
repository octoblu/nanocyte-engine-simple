debugStream = require('debug-stream')('nanocyte-engine-simple:engine-router-node')
EngineNode = require './engine-node'
combine = require 'stream-combiner2'

class EngineRouterNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineRouter} = @dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineRouter ?= require './engine-router'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata, @dependencies
      new @EngineRouter metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EngineRouterNode
