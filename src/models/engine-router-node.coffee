debugStream = require('debug-stream')('nanocyte-engine-simple:engine-router-node')
EngineNode = require './engine-node'
combine = require 'stream-combiner2'

class EngineRouterNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {NodeAssembler, @datastore, @lockManager} = dependencies
    @datastore ?= new (require './datastore')
    NodeAssembler ?= require './node-assembler'
    @EngineDebug ?= require './engine-debug'
    @lockManager ?= new (require './lock-manager')
    @nodeAssembler = new NodeAssembler()

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata
      new @EngineRouter metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineRouterNode
