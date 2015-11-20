debugStream = require('debug-stream')('nanocyte-engine-simple:nanocyte-node-wrapper')
combine = require 'stream-combiner2'

EngineNode = require './engine-node'

class NanocyteNodeWrapper
  @nodeCache : {}
  @wrap: (NanocyteClass) ->
    throw new Error 'NanocyteClass is undefined' unless NanocyteClass?
    return NanocyteNodeWrapper.nodeCache[NanocyteClass] if NanocyteNodeWrapper.nodeCache[NanocyteClass]?

    class WrappedNanocyteClass extends EngineNode
      constructor: (dependencies={}) ->
        super
        {@EngineToNanocyteStream, @NanocyteToEngineStream,@ChristacheioStream} = dependencies
        @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
        @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
        @ChristacheioStream ?= require './christacheio-stream'      

      _getEnvelopeStream: ({metadata, message}) =>
        combine.obj(
          debugStream 'in'
          new @EngineToNanocyteStream metadata
          new @ChristacheioStream metadata
          new NanocyteClass metadata
          new @FlowTimeStream metadata
          new @NanocyteToEngineStream metadata
          debugStream 'out'
        )

    NanocyteNodeWrapper.nodeCache[NanocyteClass] = WrappedNanocyteClass
    return WrappedNanocyteClass

module.exports = NanocyteNodeWrapper
