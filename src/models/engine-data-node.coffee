debugStream = require('debug-stream')('nanocyte-engine-simple:engine-data-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineDataNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineData} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineData ?= require './engine-data'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata
      new @EngineData metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineDataNode
