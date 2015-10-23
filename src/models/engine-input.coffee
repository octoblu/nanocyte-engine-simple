_         = require 'lodash'
Datastore = require './datastore'
PulseSubscriber = require './pulse-subscriber'
debug = require('debug')('nanocyte-engine-simple:engine-input')
{PassThrough} = require 'stream'

class EngineInput
  constructor: (options, dependencies={}) ->
    {@datastore,@Router,@pulseSubscriber} = dependencies
    @datastore ?= new Datastore
    @pulseSubscriber ?= new PulseSubscriber
    @Router ?= require './router'

  message: (message) =>
    stream = new PassThrough objectMode: true
    debug 'message:', fromUuid: message.fromUuid

    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe message.flowId
      return stream

    {flowId, instanceId} = message
    @_getFromNodeIds message, (error, fromNodeIds) =>
      return console.error error.stack if error?
      return console.error 'engineInput could not infer fromNodeId' if _.isEmpty fromNodeIds

      router = new @Router flowId, instanceId
      router.initialize (error) =>
        return console.error "Error initializing router:", error.message if error?
        delete message.payload?.from

        message = _.omit message, 'devices', 'flowId', 'instanceId'

        _.each fromNodeIds, (fromNodeId) =>
          router.message
            metadata:
              flowId: flowId
              instanceId: instanceId
              fromNodeId: fromNodeId
            message: message

        router.pipe stream

    return stream


  _getFromNodeIds: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, [fromNodeId] if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.hget flowId, "#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      return callback null unless config?
      callback null, _.pluck config[fromUuid], 'toNodeId'

module.exports = EngineInput
