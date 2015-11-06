{Transform} = require 'stream'
_         = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-input')
PulseSubscriber = require './pulse-subscriber'
Benchmark = require 'simple-benchmark'
mergeStream = require 'merge-stream'
EngineBatcher = require './engine-batcher'

class EngineInput extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId, @fromNodeId} = options
    {@EngineRouterNode, @pulseSubscriber} = dependencies
    @pulseSubscriber ?= new PulseSubscriber
    @EngineRouterNode ?= require './engine-router-node'
    @messageCount = 0

  _transform: ({config, data, message}, enc, next) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, => @push null
      return

    fromNodeIds = @_getFromNodeIds message, config

    if _.isEmpty fromNodeIds
      @push null
      return console.error 'engineInput could not infer fromNodeId'

    benchmark = new Benchmark label: 'engine-input'
    messageStreams = mergeStream()

    messageStreams.on 'finish', =>
      debug 'finish', benchmark.toString()
      EngineBatcher.flush @flowId, (error) =>
        console.error error if error?
        @push null

    messageStreams.on 'readable', =>
      envelope = messageStreams.read()
      @messageCount++
      if @messageCount>1000
        messageStreams.end()
      else
        @push envelope?.message

    _.each fromNodeIds, (fromNodeId) =>
      envelope = @_getEngineEnvelope message, fromNodeId, @instanceId
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
      messageCount: ++@messageCount
    message: message

  _getFromNodeIds: (message, config) =>
    fromNodeId = message.payload?.from
    return [fromNodeId] if fromNodeId?
    return [] unless config?
    _.pluck config[message.fromUuid], 'nodeId'

module.exports = EngineInput
