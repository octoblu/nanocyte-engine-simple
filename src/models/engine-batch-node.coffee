debugStream = require('debug-stream')('nanocyte-engine-simple:ngine-pulse-node')
combine = require 'stream-combiner2'
EngineNode = require './engine-node'

class EngineBatchNode extends EngineNode
  constructor: (options, @dependencies={}) ->
    super
    {@EngineBatch} = @dependencies
    @EngineBatch ?= require './engine-batch'

  _getEnvelopeStream: ({metadata, message}) =>
    combine.obj(
      debugStream 'in'
      new @EngineBatch metadata, @dependencies
      debugStream 'out'
    )

module.exports = EngineBatchNode
