debugStream = require('debug-stream')('nanocyte-engine-simple:ngine-pulse-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineBatchNode extends EngineNode
  constructor: (dependencies={}) ->
    super
    {@EngineBatch} = dependencies
    @EngineBatch ?= require './engine-batch'


  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineBatch metadata
      debugStream 'out'
    )

module.exports = EngineBatchNode
