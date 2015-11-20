colors = require 'colors'
{PassThrough} = require 'stream'
_ = require 'lodash'
async = require 'async'
redis = require 'redis'
debug = require('debug')('engine-in-a-vat')
debugStats = require('debug')('engine-in-a-vat:stats')
uuid = require 'node-uuid'

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

Engine = require '../../src/models/engine'

MessageRouteQueue = require '../../src/models/message-route-queue'
MessageProcessQueue = require '../../src/models/message-process-queue'
EngineBatchNode = require '../../src/models/engine-batch-node'
NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'

NanocytePassThrough = NanocyteNodeWrapper.wrap(require 'nanocyte-component-pass-through')

AddNodeInfoStream = require './add-node-info-stream'

{Stats} = require 'fast-stats'

class VatChannelConfig
  fetch: (callback) => callback null, {}

class EngineInAVat
  constructor: (options) ->
    {@flowName, @flowData, @instanceId} = options
    @instanceId ?= uuid.v4()
    @triggers = @findTriggers()

    debug 'created an EngineInAVat with flowName', @flowName, 'instanceId', @instanceId

    client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD

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
    @messageEngine trigger.id, message, "button", callback

  messageEngine: (nodeId, message, topic, callback=->) =>
    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration
    # EngineInAVat.messUpProcessQueue outputStream

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
        topic: topic

    engine = new Engine
    engine.run newMessage, (error) =>
      EngineInAVat.unMessUpProcessQueue()

      throw error if error?
      outputStream.end()
      callback null, EngineInAVat.getMessageStats startTime, messages

    outputStream.on 'data', (envelope) =>
      debug EngineInAVat.printMessage envelope
      messages.push envelope

    return outputStream

  subscribeToPulses: (callback)=>
    newMessage =
      metadata:
        flowId: @flowName
        instanceId: @instanceId
      message:
        topic: 'subscribe:pulse'

    engine = new Engine
    engine.run newMessage, (error) =>
      throw error if error?
      callback()

  @messUpProcessQueue: (messageStream) =>
    MessageProcessQueue.queue.kill()

    interceptProcess = (task, callback) ->
      task.node = EngineInAVat.messUpNode task.node, messageStream

      MessageProcessQueue._processMessage task, callback

    MessageProcessQueue.queue = async.queue interceptProcess, 1

  @messUpNode: (node, messageStream) =>
    node = new NanocytePassThrough() if node instanceof EngineBatchNode

    node._getEnvelopeStream = node.__getEnvelopeStream if node.__getEnvelopeStream?
    node.__getEnvelopeStream = node._getEnvelopeStream

    node._getEnvelopeStream = (envelope) =>
      messageStream.write(envelope) if envelope?
      node.__getEnvelopeStream envelope

    node

  # @messUpNodeNew: (node, messageStream) =>
  #   nodesToKeep = [EngineInputNode, EngineDebugNode, EnginePulseNode, EngineOutputNode]
  #   keepNode = false
  #   _.each nodesToKeep, (NodeToKeep) =>
  #     keepNode = true if node instanceof NodeToKeep
  #     return true


  @unMessUpProcessQueue: (messageStream) =>
    MessageProcessQueue.queue.kill()
    MessageProcessQueue.queue = async.queue MessageProcessQueue._processMessage, 1

  @getMessageStats: (startTime, messages) ->
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

    messageString = "unparsed-message"
    #messageString = JSON.stringify message
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
    #console.log JSON.stringify messages, null, 2
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
