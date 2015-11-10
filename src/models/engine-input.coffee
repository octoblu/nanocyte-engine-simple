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
      return console.error 'engineInput could not infer fromNodeId'

    @flowTime.getTimedOut (error, timedOut)=>
      if timedOut
        console.error "#{@flowId} already timed out"
        return @shutdown()

      @intervalId = setInterval @_checkTimedOut, 1000

      @_createRouters fromNodeIds, message

  _checkTimedOut: =>
    @flowTime.addTimedOut (error, timedOut) =>
      if timedOut
        console.error "#{@flowId} timed out"
        @shutdown new Error('timed out')

  shutdown: (error) =>
    debug "shutting down with error", error
    return if @shuttingDown
    @shuttingDown = true
    clearInterval @intervalId
    @flowTime.add()
    EngineBatcher.flush @flowId, (flushError) =>
      console.error flushError if flushError?
      @messageStreams.end()
      return @push null unless error?

      @sendError error, => @push null

  sendError: (error, callback) =>
    console.log "Sending error: #{error}"
    errorMessage =
      metadata:
        toNodeId: 'engine-debug'
        flowId: @flowId
        instanceId: @instanceId
        msgType: 'error'
      message: error.message

    router = new @EngineRouterNode
    router.on 'finish', callback
    router.message errorMessage

  _createRouters: (fromNodeIds, message) =>
    benchmark = new Benchmark label: 'engine-input'

    @messageStreams.on 'finish', =>
      debug 'finish', benchmark.toString()
      @shutdown()

    @messageStreams.on 'readable', =>
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
