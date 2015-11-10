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
    {@EngineRouterNode, @pulseSubscriber, FlowTime} = dependencies

    @pulseSubscriber ?= new PulseSubscriber
    @EngineRouterNode ?= require './engine-router-node'
    FlowTime ?= require './flow-time'
    @flowTime = new FlowTime flowId: @flowId
    @messageStreams = mergeStream()

  _transform: ({config, data, message}, enc, next) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, @shutdown
      return

    fromNodeIds = @_getFromNodeIds message, config

    if _.isEmpty fromNodeIds
      @shutdown()
      return console.error "#{@flowId}: engineInput could not infer fromNodeId"

    @flowTime.getTimedOut (error, timedOut)=>
      if timedOut
        console.error "#{@flowId} already timed out"
        return @shutdown()

      @_sendMessages fromNodeIds, message.payload?.from, message,

  _sendMessages: (fromNodeIds, nodeId, message) =>
    benchmark = new Benchmark label: 'engine-input'

    @messageStreams.on 'finish', =>
      debug 'finish', benchmark.toString()
      @shutdown()

    @messageStreams.on 'readable', =>
      return if @shuttingDown
      envelope = @messageStreams.read()
      @push envelope?.message

    _.each fromNodeIds, (fromNodeId) =>
      envelope = @_getEngineEnvelope message, fromNodeId, @instanceId
      router = new @EngineRouterNode

      router.stream.on 'error', (error) =>
        debug "got error from a router.", error
        @sendError error.nodeId, error, => @shutdown()

      @messageStreams.add router.message envelope

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

  _getFromNodeIds: (message, config) =>
    fromNodeId = message.payload?.from
    return [fromNodeId] if fromNodeId?
    return [] unless config?
    _.pluck config[message.fromUuid], 'nodeId'

  sendError: (nodeId, error, callback) =>
    errorMessage =
      metadata:
        toNodeId: 'router'
        fromNodeId: nodeId
        flowId: @flowId
        instanceId: @instanceId
        msgType: 'error'
      message: error.message

    debug "sending this error message", errorMessage
    router = new @EngineRouterNode
    router.stream.on 'finish', callback
    router.message errorMessage

  shutdown: (error) =>
    debug "shutting down"
    return if @shuttingDown
    @shuttingDown = true

    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
      @push null

module.exports = EngineInput
