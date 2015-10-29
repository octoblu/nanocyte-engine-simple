debugStream = require('debug-stream')('nanocyte-engine-simple:engine-router-node')
EngineNode = require './engine-node'
combine = require 'stream-combiner2'

class EngineRouterNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineRouter, @nodes} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineRouter ?= require './engine-router'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata
      new @EngineRouter metadata, nodes: @nodes
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineRouterNode
