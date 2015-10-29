{Transform} = require 'stream'
_         = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-input')
PulseSubscriber = require './pulse-subscriber'
mergeStream = require 'merge-stream'

class EngineInput extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId, @fromNodeId} = options
    {@Router,@pulseSubscriber} = dependencies
    @pulseSubscriber ?= new PulseSubscriber
    @EngineRouterNode ?= require './engine-router-node'

  _transform: ({config, data, message}, enc, next) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe message.flowId
      return next()

    fromNodeIds = @_getFromNodeIds message, config
    debug "fromNodeIds", fromNodeIds
    return console.error 'engineInput could not infer fromNodeId' if _.isEmpty fromNodeIds
    messageStreams = mergeStream()
    messageStreams.on 'finish', @end

    _.each fromNodeIds, (fromNodeId) =>
      envelope = @_getEngineEnvelope message, fromNodeId, @instanceId
      debug "creating a new router and sending this message", envelope
      router = new @EngineRouterNode
      messageStreams.add router.message envelope

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
    debug '_getFromNodeIds', message, config
    fromNodeId = message.payload?.from
    return [fromNodeId] if fromNodeId?
    _.pluck config[message.fromUuid], 'nodeId'

module.exports = EngineInput
