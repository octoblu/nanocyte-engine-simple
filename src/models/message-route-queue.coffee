async = require 'async'
EngineRouterNode = require './engine-router-node'
debug = require('debug')('nanocyte-engine-simple:message-route-queue')
MessageCounter = require './message-counter'
LockManager = require './lock-manager'

class MessageRouteQueue
  constructor: ->
    @queue = async.queue @_routeEnvelope, 1

  clear: =>
    @queue.kill()

  push: (task) =>
    {metadata} = task.envelope
    {transactionGroupId, transactionId} = metadata
    MessageCounter.add()
    LockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      metadata.transactionId = transactionId
      @queue.push task

  _routeEnvelope: ({envelope, stream}, callback) =>
    {transactionGroupId, transactionId} = envelope.metadata

    router = new EngineRouterNode

    router.stream.on 'finish', (error) =>
      LockManager.unlock transactionGroupId
      MessageCounter.subtract()
      callback()

    debug 'routing envelope:', envelope
    router.sendEnvelope envelope

module.exports = new MessageRouteQueue
