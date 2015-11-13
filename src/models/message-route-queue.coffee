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
    EngineStreamer.add router.stream

    router.stream.on 'finish', (error) =>
      stream.end()
      @_onRouteFinish error, envelope, callback

    # check for lock here
    debug 'routing envelope:', envelope
    router.message envelope

  _onRouteFinish: (error, envelope, callback) =>
    callback error if error?

    @_unlock envelope, callback

  _unlock: (envelope, callback) =>
    callback()

module.exports = new MessageRouteQueue
