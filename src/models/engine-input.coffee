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
    @flowTime = new FlowTime @flowId
    @messageStreams = mergeStream()

  _transform: ({config, data, message}, enc, next) =>
    if message.topic == 'subscribe:pulse'
      @pulseSubscriber.subscribe @flowId, => @push null
      return

    fromNodeIds = @_getFromNodeIds message, config

    if _.isEmpty fromNodeIds
      @push null
      return console.error 'engineInput could not infer fromNodeId'

    @flowTime.getTimedOut (error, timedOut)=>
      return @push null if timedOut
      @intervalId = setInterval @_checkTimedOut, 1000

      @_createRouters fromNodeIds, message

  _checkTimedOut: =>
    @flowTime.addTimedOut (error, timedOut) =>
      console.log 'checkTimedOut error:', error, 'timedOut', timedOut
      @_shutItDown() if timedOut or error?

  _shutItDown: =>
    return if @shuttingDown
    @shuttingDown = true
    @flowTime.get (error, time) =>
      console.error 'shutting it down with time', time
    @messageStreams.end()

    # errorMessage = @_getErrorMessage 'took too long'
    # router = new @EngineRouterNode
    # router.on 'finish', => @push null

    # router.message errorMessage

  _createRouters: (fromNodeIds, message) =>
    benchmark = new Benchmark label: 'engine-input'

    @messageStreams.on 'finish', =>
      debug 'finish', benchmark.toString()
      clearInterval @intervalId

      @flowTime.add =>
        EngineBatcher.flush @flowId, (error) =>
          console.error error if error?
          return @push null unless @shuttingDown

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
