_ = require 'lodash'
async = require 'async'
MessageRouteQueue = require './message-route-queue'
MessageCounter = require './message-counter'
LockManager = require './lock-manager'
ErrorHandler = require './error-handler'
NodeAssembler = require './node-assembler'

debug = require('debug')('nanocyte-engine-simple:message-process-queue')

class MessageProcessQueue
  constructor: ->
    @queue = async.queue @_processMessage, 1
    @nodes = new NodeAssembler().assembleNodes()
  clear: =>
    @queue.kill()

  push: (task) =>
    {metadata} = task.envelope
    {transactionGroupId, transactionId} = metadata
    MessageCounter.add()
    LockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      metadata.transactionId = transactionId
      @queue.push task

  _processMessage: ({node, envelope}, callback) =>    
    ToNodeClass = @nodes[node]
    node = new ToNodeClass()

    node.stream.on 'error', (error) =>
      ErrorHandler.handleError error, envelope

    node.stream.on 'finish', =>
      {transactionGroupId} = envelope.metadata
      LockManager.unlock transactionGroupId
      MessageCounter.subtract()
      callback()

    node.stream.on 'readable', =>
      MessageCounter.add()
      receivedEnvelope = node.stream.read()
      debug 'processed envelope:', receivedEnvelope

      unless receivedEnvelope?
        MessageCounter.subtract()
        return

      {metadata, message} = receivedEnvelope
      {toNodeId} = metadata

      debug 'enqueueueueing envelope', newEnvelope
      newMetadata = _.clone metadata
      newMetadata.toNodeId = 'router'

      newEnvelope =
        metadata: newMetadata
        message: message

      MessageRouteQueue.push envelope: newEnvelope
      MessageCounter.subtract()

    debug 'sending message:', envelope
    node.sendEnvelope envelope

module.exports = new MessageProcessQueue
