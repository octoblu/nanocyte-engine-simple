async = require 'async'
EngineRouterNode = require './engine-router-node'
EngineStreamer = require './engine-streamer'
debug = require('debug')('nanocyte-engine-simple:message-route-queue')

class MessageRouteQueue
  constructor: ->
    @queue = async.queue @_routeEnvelope, 1

  push: (task) =>
    @queue.push task

  _routeEnvelope: ({envelope, stream}, callback) =>
    router = new EngineRouterNode
    router.stream.on 'finish', (error) =>
      @_onRouteFinish error, envelope, callback

    # check for lock here
    debug 'routing envelope:', envelope
    router.sendEnvelope envelope

  _onRouteFinish: (error, envelope, callback) =>
    EngineStreamer.subtract()
    callback error if error?

    @_unlock envelope, callback

  _unlock: (envelope, callback) =>
    callback()

module.exports = new MessageRouteQueue
