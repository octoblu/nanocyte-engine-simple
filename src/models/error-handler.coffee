_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:error-handler')

class ErrorHandler

  constructor: (@options, dependencies) ->
    @updateDependencies dependencies

  updateDependencies: (@dependencies) =>
    { @messageCounter,
      @messageRouteQueue,
      @messageProcessQueue,
      @engineBatcher,
      @EngineDebugNode } = @dependencies
    @EngineDebugNode ?= require './engine-debug-node'

  fatalError: (error, envelope) =>
    @messageCounter.onDone =>
    @hasFatalError = true
    @messageRouteQueue.clear()
    @messageProcessQueue.clear()
    @sendError error, envelope, @callback

  setFlowInfo: (@flowId, @instanceId) =>

  onFatalError: (@callback) =>

  sendError: (error, envelope={}, callback=->) =>
    @messageCounter.add()
    {metadata, config} = envelope

    debugEnvelope =
      metadata:
        toNodeId: 'engine-debug'
        fromNodeId: metadata?.toNodeId
        flowId: @flowId
        instanceId: @instanceId
        msgType: 'error'
      message: error.message

    debug "sending this error envelope", debugEnvelope
    engineDebugNode = new @EngineDebugNode @options, @dependencies

    engineDebugNode.stream.on 'readable', =>
      debug 'got debugNode data'

      envelope = engineDebugNode.stream.read()
      debug "envelope was", envelope

      unless envelope?
        callback null, error
        return @messageCounter.subtract()

      outputEnvelope =
        metadata: _.extend {}, debugEnvelope.metadata, toNodeId: 'engine-output'
        message: envelope.message

      @engineBatcher.push @flowId, outputEnvelope

    engineDebugNode.sendEnvelope debugEnvelope

module.exports = ErrorHandler
