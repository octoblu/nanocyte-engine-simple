async = require 'async'
EngineRouterNode = require './engine-router-node'
debug = require('debug')('nanocyte-engine-simple:message-route-queue')

class MessageRouteQueue
  constructor: (@options, @dependencies) ->
    {@lockManager, @messageCounter} = @dependencies
    @queue = async.queue @_routeEnvelope, 1

  clear: =>
    @queue.kill()

  push: (task) =>
    {metadata} = task.envelope
    {transactionGroupId, transactionId} = metadata
    @messageCounter.add()
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      metadata.transactionId = transactionId
      @queue.push task

  _routeEnvelope: ({envelope, stream}, callback) =>
    {transactionGroupId, transactionId} = envelope.metadata

    router = new EngineRouterNode @options, @dependencies

    router.stream.on 'finish', (error) =>
      @lockManager.unlock transactionGroupId
      @messageCounter.subtract()
      callback()

    debug 'routing envelope:', envelope
    router.sendEnvelope envelope

module.exports = MessageRouteQueue
