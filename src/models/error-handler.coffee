_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:error-handler')

EngineDebugNode = require './engine-debug-node'
EngineOutputNode = require './engine-output-node'

class ErrorHandler
  handleError: (error, envelope) =>
    MessageRouteQueue = require './message-route-queue'
    MessageProcessQueue = require './message-process-queue'

    MessageRouteQueue.clear()
    MessageProcessQueue.clear()
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

      engineOutputNode = new EngineOutputNode
      engineOutputNode.stream.on 'finish', =>
        callback null, error

      outputEnvelope =
        metadata: _.extend {}, debugEnvelope.metadata, toNodeId: 'engine-output'
        message: envelope.message

      engineOutputNode.sendEnvelope outputEnvelope

    engineDebugNode.sendEnvelope debugEnvelope

module.exports = new ErrorHandler
