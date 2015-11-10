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
    @messageStreams = mergeStream()

  _transform: ({config, data, message}, enc, next) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, @flushAndEnd
      return

    fromNodeIds = @_getFromNodeIds message, config

    if _.isEmpty fromNodeIds
      @flushAndEnd()
      return console.error 'engineInput could not infer fromNodeId'

    @_createRouters fromNodeIds, message

  flushAndEnd: =>
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
      @messageStreams.end()
      @push null

  _createRouters: (fromNodeIds, message) =>
    benchmark = new Benchmark label: 'engine-input'

    @messageStreams.on 'finish', =>
      debug 'finish', benchmark.toString()
      @flushAndEnd()

    @messageStreams.on 'readable', =>
      return if @shuttingDown
      envelope = @messageStreams.read()
      @push envelope?.message

    _.each fromNodeIds, (fromNodeId) =>
      envelope = @_getEngineEnvelope message, fromNodeId, @instanceId
      router = new @EngineRouterNode
      @messageStreams.add router.message envelope

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
