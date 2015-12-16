_ = require 'lodash'
async = require 'async'
NodeAssembler = require './node-assembler'

debug = require('debug')('nanocyte-engine-simple:message-process-queue')

class MessageProcessQueue
  constructor: (@options, @dependencies) ->
    {@messageRouteQueue, @messageCounter, @lockManager, @errorHandler} = @dependencies
    @queue = async.queue @_processMessage, 1
    @nodes = new NodeAssembler(@options, @dependencies).assembleNodes()

  clear: =>
    @queue.kill()

  push: (task) =>
    {transactionGroupId, transactionId} = task.envelope.metadata
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      throw error if error?
      task.envelope.metadata.transactionId = transactionId
      @queue.push task

  _processMessage: (task, callback) =>
    {nodeType, envelope} = task
    {transactionGroupId, transactionId} = envelope.metadata
    debug 'sending message:', envelope
    NodeClass = @nodes[nodeType]
    node = new NodeClass @options, @dependencies
    @_addStreamCallbacks task, node, callback
    node.sendEnvelope envelope

  _addStreamCallbacks: (task, node, callback) ->
    {envelope} = task
    {transactionGroupId} = envelope.metadata

    node.stream.on 'error', (error) =>
      @errorHandler.handleError error, envelope

    node.stream.on 'finish', =>
      @lockManager.unlock transactionGroupId
      callback()

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
