debugStream = require('debug-stream')('nanocyte-engine-simple:engine-data-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineDataNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineData} = @dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineData ?= require './engine-data'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata, @dependencies
      new @EngineData metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EngineDataNode
