debugStream = require('debug-stream')('nanocyte-engine-simple:engine-input-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineInputNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream,@NanocyteToEngineStream,@EngineInput,@DatastoreCheckKeyStream,@EngineBatch} = dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineInput ?= require './engine-input'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata
      new @EngineInput metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineInputNode
