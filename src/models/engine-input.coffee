_         = require 'lodash'
Datastore = require './datastore'
Router    = require './router'
PulseSubscriber = require './pulse-subscriber'
debug = require('debug')('nanocyte-engine-simple:engine-input')

class EngineInput
  constructor: (options, dependencies={}) ->
    {@datastore,@router,@pulseSubscriber} = dependencies
    @datastore ?= new Datastore
    @pulseSubscriber ?= new PulseSubscriber

  onMessage: (message) =>
    debug 'onMessage:', fromUuid: message.fromUuid
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe message.flowId
      return

    {flowId, instanceId} = message
    @_getFromNodeIds message, (error, fromNodeIds) =>
      return console.error error.stack if error?
      return console.error 'engineInput could not infer fromNodeId' if _.isEmpty fromNodeIds

      router = new Router flowId, instanceId
      router.initialize (error) =>
        return console.error "Error initializing router:", error.message if error?

        message = _.omit message, 'devices', 'flowId', 'instanceId'
        delete message?.payload?.from

        _.each fromNodeIds, (fromNodeId) =>
          router.write
            metadata:
              fromNodeId: fromNodeId
            message: message


  _getFromNodeIds: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, [fromNodeId] if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.hget flowId, "#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      return callback null unless config?
      callback null, _.pluck config[fromUuid], 'nodeId'

module.exports = EngineInput
