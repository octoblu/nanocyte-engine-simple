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

    @pulseSubscriber ?= new PulseSubscriber

  _transform: ({config, data, message}, enc, next) =>
    debug 'config', config
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, =>
        return @push null

    fromNodeId = @_getFromNodeId message, config

    return @push null unless fromNodeId?

    @_sendEnvelope fromNodeId, message.payload?.from, message,

  _sendEnvelope: (fromNodeId, nodeId, message) =>
    envelope = @_getEngineEnvelope message, fromNodeId
    MessageRouteQueue.push envelope: envelope
    @push null

  _getEngineEnvelope: (message, fromNodeId) =>
    delete message.payload?.from
    message = _.omit message, 'devices', 'flowId', 'instanceId'

    metadata:
      toNodeId: 'router'
      flowId: @flowId
      instanceId: @instanceId
      fromNodeId: fromNodeId
      flowTime: @flowTime
    message: message

  _getFromNodeId: (message, config) =>
    fromNodeId = message.payload?.from
    return fromNodeId if fromNodeId?
    return unless config?

    config[message.fromUuid]?.nodeId

module.exports = EngineInput
