debugStream = require('debug-stream')('nanocyte-engine-simple:nanocyte-node-wrapper')
combine = require 'stream-combiner2'

EngineNode = require './engine-node'

class NanocyteNodeWrapper
  constructor: (options, @dependencies)->
    @nodeCache = {}

  wrap: (NanocyteClass) ->
    throw new Error 'NanocyteClass is undefined' unless NanocyteClass?
    return @nodeCache[NanocyteClass] if @nodeCache[NanocyteClass]?

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
          new @EngineToNanocyteStream metadata, @dependencies
          new @ChristacheioStream metadata, @dependencies
          new NanocyteClass metadata, @dependencies
          new @NanocyteToEngineStream metadata, @dependencies
          debugStream 'out'
        )

    @nodeCache[NanocyteClass] = WrappedNanocyteClass
    return WrappedNanocyteClass

module.exports = NanocyteNodeWrapper
