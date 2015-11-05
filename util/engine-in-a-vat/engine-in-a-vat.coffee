fs = require 'fs'
colors = require 'colors'
{PassThrough} = require 'stream'
_ = require 'lodash'

redis = require 'redis'
debug = require('debug')('engine-in-a-vat')
debugStats = require('debug')('engine-in-a-vat:stats')
EngineRouterNode = require '../../src/models/engine-router-node'

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

getVatNodeAssembler = require './get-vat-node-assembler'
AddNodeInfoStream = require './add-node-info-stream'
PulseSubscriber = require '../../src/models/pulse-subscriber'
EngineBatcher = require '../../src/models/engine-batcher'

{Stats} = require 'fast-stats'

class VatChannelConfig
  fetch: (callback) => callback null, {}

class EngineInAVat
  constructor: (options) ->
    {@flowName, @flowData} = options
    @instanceId = 'engine-in-a-vat'
    @triggers = @findTriggers()

    client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD
    client.unref()

    @pulseSubscriber ?= new PulseSubscriber
    @configurationGenerator = new ConfigurationGenerator {}, channelConfig: new VatChannelConfig
    @configurationSaver = new ConfigurationSaver client

  initialize: (callback=->) =>
    #pay the cost of loading up all the nanocytes up front.
    NodeAssembler = getVatNodeAssembler()
    (new NodeAssembler).assembleNodes()

    debug 'initializing'
    @configurationGenerator.configure flowData: @flowData, userData: {}, (error, configuration) =>
      return console.error "config generator had an error!", error if error?
      debug 'configured'
      @configuration = configuration

      @configurationSaver.save flowId: @flowName, instanceId: @instanceId, flowData: configuration, (error, result)=>
        return console.error "config saver had an error!", error if error?
        debug 'saved'
        callback(null, configuration)

  triggerByName: ({name, message}, callback=->) =>
    trigger = @triggers[name]
    throw new Error "Can't find a trigger named '#{name}'" unless trigger?
    @messageRouter trigger.id, message, callback

  messageRouter: (nodeId, message, callback=->) =>
    startTime = Date.now()
    messages = []

    @pulseSubscriber.subscribe @flowName

    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration
    envelope =
      metadata:
        fromNodeId: nodeId
        flowId: @flowName
        instanceId: @instanceId
        toNodeId: 'router'
      message: message
    NodeAssembler = getVatNodeAssembler(outputStream)

    router = new EngineRouterNode nodes: new NodeAssembler().assembleNodes()

    routerStream = router.message envelope

    routerStream.on 'data', (envelope) =>
      debug "writing to outputStream"
      outputStream.write envelope

    routerStream.on 'finish', =>
      debug "router finished"
      EngineBatcher.flush @flowId, (error) =>
        console.error error if error?
        EngineInAVat.printMessageStats messages
        outputStream.end()
        callback null, EngineInAVat.getMessageStats startTime, messages


    outputStream.on 'data', (envelope) =>
      debug EngineInAVat.printMessage envelope
      messages.push envelope

    outputStream

  @getMessageStats: (startTime, messages) ->
    previousTime = startTime

    messageTimes = _.map messages, (message) =>
      thisTime = message.debugInfo.timestamp
      elapsed  = thisTime - previousTime
      previousTime = thisTime
      return elapsed

    stats = new Stats()
    stats.push messageTimes
    mean = _.round stats.amean(), 2
    errorMargin = _.round stats.moe(), 2

    messageStats =
      mean:
        actualMean: mean
        errorMargin: errorMargin
        upperLimit95: mean + errorMargin
        lowerLimit95: mean - errorMargin

      median: stats.median()
      total: _.sum messageTimes
      range:
        from: stats.range()[0]
        to: stats.range()[1]

    return messageStats

  @printMessage: (envelope) ->
    {debugInfo, metadata, message} = envelope
    messageString = JSON.stringify message
    lastTime = debugInfo.timestamp unless lastTime?
    timeDiff = debugInfo.timestamp - lastTime
    lastTime = debugInfo.timestamp

    "[#{colors.yellow metadata.transactionId}] " +
    "#{debugInfo.fromNode?.config.name || metadata.fromNodeId} #{colors.gray debugInfo.fromNode?.config.type} : " +
    "--> " +
    "#{debugInfo.toNode?.config.name || metadata.toNodeId} #{colors.green debugInfo.nanocyteType} (#{debugInfo.toNode?.config.type})" +
    " #{colors.green messageString}"

  findTriggers: =>
    _.indexBy _.filter(@flowData.nodes, type: 'operation:trigger'), 'name'


  unbatchMessages: (envelope) =>
    return [envelope] unless envelope.message.payload?
    unbatchedMessages = []
    # console.log envelope.message.payload
    return [envelope]

  @printMessageStats: (messages) =>
    debugStats "\nINCOMING:"
    @printIncomingMessages messages
    debugStats "\nOUTGOING:"
    @getOutgoingMessages messages

  @printIncomingMessages: (messages) =>

    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.debugInfo.toNode?.config.name || envelope.metadata.toNodeId
    _.each messagesByType, (messages, type) =>
      debugStats "#{type} got #{messages.length} messages"

  @getOutgoingMessages: (messages) =>
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.debugInfo.fromNode?.config.name || envelope.metadata.fromNodeId

    _.each messagesByType, (messages, type) =>
      return unless type?

      nodeNames = _.compact _.map messages, (envelope) =>
        return envelope.debugInfo.toNode?.config.name || envelope.metadata.toNodeId

      debugStats "#{type} sent #{messages.length} messages to", nodeNames

      return nodeNames

module.exports = EngineInAVat
