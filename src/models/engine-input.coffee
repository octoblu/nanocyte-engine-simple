{Transform} = require 'stream'
_         = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-input')

class EngineInput extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId, @fromNodeId} = metadata
    {@route, @forwardedRoutes} = metadata.metadata
    {PulseSubscriber, @pulseSubscriber, @messageRouteQueue} = dependencies
    PulseSubscriber ?= require './pulse-subscriber'
    @pulseSubscriber ?= new PulseSubscriber null, dependencies

  _done: (next, error) =>
    @push null
    next(error) if next?

  _transform: ({config, data, message}, enc, next) =>
    debug 'config', config
    if message.topic == 'subscribe:pulse'
      return @pulseSubscriber.subscribe @flowId, => @_done next

    if message.topic == 'ping'
      @_sendEnvelopes(['engine-ping-input'], message) unless _.isEmpty config
      return @_done next

    if message.topic == 'message-batch'
      return @_done next

    fromNodeIds = @_getFromNodeIds message, config
    @_sendEnvelopes fromNodeIds, message unless _.isEmpty fromNodeIds
    @_done next

  _sendEnvelopes:(fromNodeIds, config) =>
    _.each fromNodeIds, (fromNodeId) =>
      @_sendEnvelope fromNodeId, config

  _sendEnvelope: (fromNodeId, message) =>
    envelope = @_getEngineEnvelope message, fromNodeId
    @messageRouteQueue.push envelope: envelope

  _getEngineEnvelope: (message, fromNodeId) =>
    message = @_formatMessage message

    metadata:
      toNodeId: 'router'
      flowId: @flowId
      instanceId: @instanceId
      fromNodeId: fromNodeId
      originalMessage: message
      metadata:
        route: @route
        forwardedRoutes: @forwardedRoutes
    message: message

  _formatMessage: (message) =>
    delete message.payload?.from
    message = _.omit message, 'devices', 'flowId', 'instanceId'
    return message unless message.payload?.replacePayload?
    return _.defaults {payload: message.payload[message.payload.replacePayload]}, message

  _getFromNodeIds: (message, config) =>
    from = message.payload?.from

    if from?
      alias = @_getNodeIdFromAlias from, config
      debug "alias is", alias
      return [alias || from]

    return [] unless config?
    _.pluck config[message.fromUuid], 'nodeId'

  _getNodeIdFromAlias: (alias, config) =>
    #definitely does not have bugs this time. For real.
    return _.reduce(config, (result, value) =>
      nodeData = _.find value, alias: alias
      return nodeData.nodeId if nodeData?.nodeId?
      return result
    , null)

module.exports = EngineInput
