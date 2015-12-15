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
    {metadata} = task.envelope
    {transactionGroupId, transactionId} = metadata
    @messageCounter.add()
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      metadata.transactionId = transactionId
      @queue.push task

  _processMessage: ({nodeType, envelope}, callback) =>
    ToNodeClass = @nodes[nodeType]
    node = new ToNodeClass @options, @dependencies
    
    node.stream.on 'error', (error) =>
      @errorHandler.handleError error, envelope

    node.stream.on 'finish', =>
      {transactionGroupId} = envelope.metadata
      @lockManager.unlock transactionGroupId
      @messageCounter.subtract()
      callback()

    node.stream.on 'readable', =>
      @messageCounter.add()
      receivedEnvelope = node.stream.read()
      debug 'processed envelope:', receivedEnvelope

      unless receivedEnvelope?
        @messageCounter.subtract()
        return

      {metadata, message} = receivedEnvelope
      {toNodeId} = metadata

      debug 'enqueueueueing envelope', newEnvelope
      newMetadata = _.clone metadata
      newMetadata.toNodeId = 'router'

      newEnvelope =
        metadata: newMetadata
        message: message

      @messageRouteQueue.push envelope: newEnvelope
      @messageCounter.subtract()

    debug 'sending message:', envelope
    node.sendEnvelope envelope

module.exports = MessageProcessQueue
