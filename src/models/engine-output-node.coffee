debugStream = require('debug-stream')('nanocyte-engine-simple:engine-output-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineOutputNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineToNanocyteStream, @NanocyteToEngineStream, @EngineOutput, @EngineThrottle} = dependencies

    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @EngineOutput ?= require './engine-output'
    @EngineThrottle ?= require './engine-throttle'

  _getEnvelopeStream: ({metadata, message}) =>
    console.log 'hi'
    combine.obj(
      debugStream 'in'
      new @EngineToNanocyteStream metadata
      new @EngineThrottle metadata
      new @EngineOutput metadata
      new @NanocyteToEngineStream metadata
      debugStream 'out'
    )

module.exports = EngineOutputNode
