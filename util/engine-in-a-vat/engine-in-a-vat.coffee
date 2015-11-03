fs = require 'fs'
colors = require 'colors'
{PassThrough} = require 'stream'
_ = require 'lodash'

redis = require 'redis'
debug = require('debug')('engine-in-a-vat')
EngineRouterNode = require '../../src/models/engine-router-node'

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

getVatNodeAssembler = require './get-vat-node-assembler'
AddNodeInfoStream = require './add-node-info-stream'
PulseSubscriber = require '../../src/models/pulse-subscriber'

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
    debug 'initializing'
    @configurationGenerator.configure flowData: @flowData, userData: {}, (error, configuration) =>
      return console.error "config generator had an error!", error if error?
      debug 'configured'
      @configuration = configuration

      @configurationSaver.save flowId: @flowName, instanceId: @instanceId, flowData: configuration, (error, result)=>
        return console.error "config saver had an error!", error if error?
        debug 'saved'
        callback(null, configuration)

  triggerByName: ({name, message}) =>
    trigger = @triggers[name]
    throw new Error "Can't find a trigger named '#{name}'" unless trigger?
    @messageRouter trigger.id, message

  messageRouter: (nodeId, message) =>
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

    router.message(envelope).pipe outputStream
    outputStream.on 'data', (envelope) => debug EngineInAVat.printMessage(envelope)
        
    outputStream

  @printMessage: (envelope) ->
    {debugInfo, metadata, message} = envelope
    messageString = JSON.stringify message
    lastTime = debugInfo.timestamp unless lastTime?
    timeDiff = debugInfo.timestamp - lastTime
    lastTime = debugInfo.timestamp

    "[#{colors.yellow metadata.transactionId}] " +
    "#{debugInfo.fromNode.config.name || metadata.fromNodeId} #{colors.green debugInfo.nanocyteType} #{colors.gray debugInfo.fromNode.config.type} : " +
    "--> " +
    "#{debugInfo.toNode.config.name || metadata.toNodeId} (#{debugInfo.toNode.config.type})" +
    " #{colors.green messageString}"

  findTriggers: =>
    _.indexBy _.filter(@flowData.nodes, type: 'operation:trigger'), 'name'


  @printMessageStats: (messages) =>
    console.log "\nINCOMING:"
    @printIncomingMessages messages
    console.log "\nOUTGOING:"
    @printOutgoingMessages messages

  @printIncomingMessages: (messages) =>
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.debugInfo.toNode.config.name || envelope.debugInfo.nanocyteType
    _.each messagesByType, (messages, type) =>
      console.log "#{type} got #{messages.length} messages"

  @printOutgoingMessages: (messages) =>
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.debugInfo.fromNode.config.name

    _.each messagesByType, (messages, type) =>
      return unless type?
      nodeNames = _.compact _.map messages, (envelope) =>
        return envelope.debugInfo.toNode.config.name

      console.log "#{type} sent #{messages.length} messages to", nodeNames



module.exports = EngineInAVat
