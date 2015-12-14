_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:error-handler')

EngineDebugNode = require './engine-debug-node'
EngineBatchNode = require './engine-batch-node'

class ErrorHandler

  constructor: (options, @dependencies) ->
    {@messageRouteQueue, @messageProcessQueue} = @dependencies

  handleError: (error, envelope) =>
    @messageRouteQueue.clear()
    @messageProcessQueue.clear()
    @sendError error, envelope, @callback

  onError: (@callback) =>

  sendError: (error, envelope, callback) =>
    {metadata, message} = envelope

    debugEnvelope =
      metadata:
        toNodeId: 'engine-debug'
        fromNodeId: metadata.toNodeId
        flowId: metadata.flowId
        instanceId: metadata.instanceId
        msgType: 'error'
      message: error.message

    debug "sending this error envelope", debugEnvelope

    engineDebugNode = new EngineDebugNode

    engineDebugNode.stream.on 'readable', =>
      envelope = engineDebugNode.stream.read()
      return unless envelope?

      engineBatchNode = new EngineBatchNode @dependencies
      engineBatchNode.stream.on 'finish', =>
        callback null, error

      outputEnvelope =
        metadata: _.extend {}, debugEnvelope.metadata, toNodeId: 'engine-output'
        message: envelope.message

      engineBatchNode.sendEnvelope outputEnvelope

    engineDebugNode.sendEnvelope debugEnvelope

module.exports = ErrorHandler
