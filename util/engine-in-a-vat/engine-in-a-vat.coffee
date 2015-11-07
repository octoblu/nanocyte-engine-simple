fs = require 'fs'
colors = require 'colors'
{PassThrough} = require 'stream'
_ = require 'lodash'

redis = require 'redis'
debug = require('debug')('engine-in-a-vat')
debugStats = require('debug')('engine-in-a-vat:stats')

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

getEngineInputNode = require './get-engine-input-node'
AddNodeInfoStream = require './add-node-info-stream'

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

        @subscribeToPulses =>
          callback(null, configuration)

  triggerByName: ({name, message}, callback=->) =>
    trigger = @triggers[name]
    throw new Error "Can't find a trigger named '#{name}'" unless trigger?
    @messageEngine trigger.id, message, callback

  messageEngine: (nodeId, message, callback=->) =>
    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration

    VatEngineInputNode = getEngineInputNode outputStream
    engineInputNode = new VatEngineInputNode

    startTime = Date.now()
    messages = []
    newMessage =
      metadata:
        flowId: @flowName
        instanceId: @instanceId
      message:
        payload:
          message: message
          from: nodeId

    engineInputStream = engineInputNode.message newMessage

    engineInputStream.on 'data', (envelope) =>
      debug EngineInAVat.printMessage envelope
      messages.push envelope
      outputStream.write envelope

    engineInputStream.on 'finish', =>
      outputStream.end()
      callback null, EngineInAVat.getMessageStats startTime, messages

    return outputStream

  subscribeToPulses: (callback)=>
    VatEngineInputNode = getEngineInputNode(new PassThrough objectMode: true)
    engineInputNode = new VatEngineInputNode

    newMessage =
      metadata:
        flowId: @flowName
        instanceId: @instanceId
      message:
        topic: 'subscribe:pulse'

    engineInputStream = engineInputNode.message newMessage

    engineInputStream.on 'data', (envelope) =>

    engineInputStream.on 'finish', => callback()

    return engineInputStream


  @getMessageStats: (startTime, messages) ->
    return ''
    previousTime = startTime

    messageTimes = _.map messages, (message) =>
      thisTime = Date.now()
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
    {metadata, message} = envelope
    debugInfo = metadata.debugInfo || {}

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

  @printMessageStats: (messages) =>
    debugStats "\nINCOMING:"
    @printIncomingMessages messages
    debugStats "\nOUTGOING:"
    @getOutgoingMessages messages

  @printIncomingMessages: (messages) =>
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.metadata.debugInfo.toNode?.config.name || envelope.metadata.toNodeId
    _.each messagesByType, (messages, type) =>
      debugStats "#{type} got #{messages.length} messages"

  @getOutgoingMessages: (messages) =>
    console.log JSON.stringify messages, null, 2
    process.exit -1
    messagesByType = _.groupBy messages, (envelope) =>
      return envelope.metadata.debugInfo.fromNode?.config.name || envelope.metadata.fromNodeId

    _.each messagesByType, (messages, type) =>
      return unless type?

      nodeNames = _.compact _.map messages, (envelope) =>
        return envelope.metadata.debugInfo.toNode?.config.name || envelope.metadata.toNodeId

      debugStats "#{type} sent #{messages.length} messages to", nodeNames

      return nodeNames

module.exports = EngineInAVat
