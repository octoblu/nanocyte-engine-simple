debugStream = require('debug-stream')('nanocyte-engine-simple:engine-input-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineInputNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineToNanocyteStream,@NanocyteToEngineStream,@EngineInput,@DatastoreCheckKeyStream,@EngineBatch} = @dependencies
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineInput ?= require './engine-input'

  _getEnvelopeStream: ({metadata, message}) =>

    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata, @dependencies
      new @EngineInput metadata, @dependencies
      new @NanocyteToEngineStream metadata, @dependencies
      debugStream 'out'
    )

module.exports = EngineInputNode
