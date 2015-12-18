_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:error-handler')

EngineDebugNode = require './engine-debug-node'
EngineBatchNode = require './engine-batch-node'

class ErrorHandler

  constructor: (@options, dependencies) ->
    @updateDependencies dependencies

  updateDependencies: (@dependencies) =>
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

    engineDebugNode = new EngineDebugNode @options, @dependencies

    engineDebugNode.stream.on 'readable', =>
      debug 'got debugNode data'

      envelope = engineDebugNode.stream.read()
      debug "envelope was", envelope
      return unless envelope?

      engineBatchNode = new EngineBatchNode @options, @dependencies
      engineBatchNode.stream.on 'finish', =>
        debug 'calling the callback on stream finish!'
        callback null, error

      engineBatchNode.stream.on 'readable', =>
        engineBatchNode.stream.read()

      outputEnvelope =
        metadata: _.extend {}, debugEnvelope.metadata, toNodeId: 'engine-output'
        message: envelope.message

      engineBatchNode.sendEnvelope outputEnvelope, =>
        debug 'calling the callback!'
        callback null, error


    engineDebugNode.sendEnvelope debugEnvelope

module.exports = ErrorHandler
