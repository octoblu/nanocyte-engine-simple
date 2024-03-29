async = require 'async'
EngineRouterNode = require './engine-router-node'
debug = require('debug')('nanocyte-engine-simple:message-route-queue')
_ = require 'lodash'

class MessageRouteQueue
  constructor: (@options, @dependencies) ->
    {@lockManager, @messageCounter, @errorHandler} = @dependencies
    @queue = async.queue @_routeEnvelope, 1

  clear: =>
    @queue.kill()

  push: (task) =>
    return if @errorHandler.hasFatalError
    {transactionGroupId, transactionId} = task.envelope.metadata
    @lockManager.lock transactionGroupId, transactionId, (error, transactionId) =>
      throw error if error?
      task.envelope.metadata.transactionId = transactionId
      @queue.push task

  _routeEnvelope: (task, callback) =>
    {envelope} = task
    debug 'routing envelope:', envelope
    node = new EngineRouterNode @options, @dependencies
    @_addStreamCallbacks task, node, callback
    node.sendEnvelope envelope

  _addStreamCallbacks: (task, node, callback) ->
    {envelope} = task
    {transactionGroupId} = envelope.metadata
    node.stream.on 'finish', (error) =>
      callback()
      @lockManager.unlock transactionGroupId

module.exports = MessageRouteQueue
