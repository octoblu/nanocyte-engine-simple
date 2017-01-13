_             = require 'lodash'
async         = require 'async'
NodeAssembler = require './node-assembler'
debug         = require('debug')('nanocyte-engine-simple:message-process-queue')

class MessageProcessQueue
  constructor: (@options, @dependencies) ->
    {@messageRouteQueue, @messageCounter, @lockManager, @errorHandler} = @dependencies
    @queue = async.queue @_processMessage, 1
    @nodes = new NodeAssembler(@options, @dependencies).assembleNodes()

  clear: =>
    @queue.kill()

  push: (task) =>
    return if @errorHandler.hasFatalError
    {transactionGroupId, transactionId} = task.envelope.metadata
    return @errorHandler.fatalError new Error("messageCounter.max is too high!") if @messageCounter.max > 2000
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      throw error if error?
      task.envelope.metadata.transactionId = transactionId
      @queue.push task

  _processMessage: (task, callback) =>
    {nodeType, envelope} = task
    {transactionGroupId, transactionId} = envelope.metadata
    debug 'sending message:', envelope
    NodeClass = @nodes[nodeType]
    return @errorHandler.fatalError new Error("#{nodeType} is not a valid nanocyte node") unless _.isFunction NodeClass
    node = new NodeClass @options, @dependencies
    @_addStreamCallbacks task, node, callback
    node.sendEnvelope envelope

  _addStreamCallbacks: (task, node, callback) ->
    {nodeType, envelope} = task
    {transactionGroupId} = envelope.metadata

    finished = _.once =>
      callback()
      @lockManager.unlock transactionGroupId

    node.stream.on 'error', (error) =>
      @errorHandler.sendError error, envelope
      finished()

    node.stream.on 'finish', finished

    node.stream.on 'readable', =>
      receivedEnvelope = node.stream.read()
      debug 'processed envelope:', receivedEnvelope
      return unless receivedEnvelope?

      {metadata, message} = receivedEnvelope
      {toNodeId} = metadata

      debug 'enqueueueueing envelope', newEnvelope
      newMetadata = _.clone metadata
      newMetadata.toNodeId = 'router'

      newEnvelope =
        metadata: newMetadata
        message: message

      @messageRouteQueue.push envelope: newEnvelope

module.exports = MessageProcessQueue
