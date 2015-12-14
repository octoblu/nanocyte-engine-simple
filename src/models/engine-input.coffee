{Transform} = require 'stream'
_         = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-input')
PulseSubscriber = require './pulse-subscriber'
MessageRouteQueue = require './message-route-queue'

class EngineInput extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId, @fromNodeId} = metadata
    {@pulseSubscriber} = dependencies

    @pulseSubscriber ?= new PulseSubscriber null, dependencies

  _transform: ({config, data, message}, enc, next) =>
    debug 'config', config
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, =>
        return @push null

    fromNodeIds = @_getFromNodeIds message, config

    return @push null if _.isEmpty fromNodeIds

    @_sendEnvelopes fromNodeIds, message


  _sendEnvelopes:(fromNodeIds, config) =>
    _.each fromNodeIds, (fromNodeId) =>
       @_sendEnvelope fromNodeId, config

    @push null


  _sendEnvelope: (fromNodeId, message) =>
    envelope = @_getEngineEnvelope message, fromNodeId
    MessageRouteQueue.push envelope: envelope

  _getEngineEnvelope: (message, fromNodeId) =>
    delete message.payload?.from
    message = _.omit message, 'devices', 'flowId', 'instanceId'

    metadata:
      toNodeId: 'router'
      flowId: @flowId
      instanceId: @instanceId
      fromNodeId: fromNodeId
    message: message

  _getFromNodeIds: (message, config) =>
    fromNodeId = message.payload?.from
    return [fromNodeId] if fromNodeId?
    return [] unless config?
    _.pluck config[message.fromUuid], 'nodeId'

module.exports = EngineInput
