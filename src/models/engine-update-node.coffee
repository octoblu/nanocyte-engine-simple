debugStream = require('debug-stream')('nanocyte-engine-simple:engine-update-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineUpdateNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineUpdate, @EngineUpdateThrottle} = @dependencies

    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineUpdate ?= require './engine-update'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata, @dependencies
      new @EngineUpdate metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EngineUpdateNode
