_         = require 'lodash'
Datastore = require './datastore'
Router    = require './router'
PulseSubscriber = require './pulse-subscriber'

class EngineInput
  constructor: (options, dependencies={}) ->
    {@datastore,@router,@pulseSubscriber} = dependencies
    @datastore ?= new Datastore
    @router    ?= new Router
    @pulseSubscriber ?= new PulseSubscriber

  onMessage: (message) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe message.flowId

    @_getFromNodeIds message, (error, fromNodeIds) =>
      return console.error error.stack if error?
      return console.error 'engineInput could not infer fromNodeId' if _.isEmpty fromNodeIds

      flowId = message.flowId
      instanceId = message.instanceId
      message = _.omit message, 'devices', 'flowId', 'instanceId'
      delete message?.payload?.from

      _.each fromNodeIds, (fromNodeId) =>
        @router.onEnvelope
          flowId:     flowId
          instanceId: instanceId
          fromNodeId: fromNodeId
          message:    message

  _getFromNodeIds: (message, callback) =>
    fromNodeId = message.payload?.from
    return callback null, [fromNodeId] if fromNodeId?

    {flowId,instanceId,fromUuid} = message
    @datastore.hget flowId, "#{instanceId}/engine-input/config", (error, config) =>
      return callback error if error?
      return callback null unless config?
      callback null, _.pluck config[fromUuid], 'nodeId'

module.exports = EngineInput
