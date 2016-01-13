{Transform,PassThrough} = require 'stream'
_ = require 'lodash'
redis = require 'redis'
debug = require('debug')('engine-in-a-vat')
uuid = require 'node-uuid'

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

Engine = require '../../src/models/engine'

EngineOutputFactory = require './engine-output-factory'
AddNodeInfoStream = require './add-node-info-stream'
MessageUtil = require './message-util'

class VatChannelConfig
  fetch: (callback) => callback null, {}

class EngineInAVat
  constructor: (@options) ->
    {@flowName, @flowData, @instanceId} = @options
    @instanceId ?= uuid.v4()
    @triggers = @findTriggers()
    client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD
    @configurationGenerator = new ConfigurationGenerator {}, channelConfig: new VatChannelConfig
    @configurationSaver = new ConfigurationSaver client
    debug 'created an EngineInAVat with flowName', @flowName, 'instanceId', @instanceId

  findTriggers: =>
    _.indexBy _.filter(@flowData.nodes, type: 'operation:trigger'), 'name'

  triggerByName: ({name, message}, callback=->) =>
    trigger = @triggers[name]
    throw new Error "Can't find a trigger named '#{name}'" unless trigger?
    @messageEngine trigger.id, message, "button", callback

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

  getEngineDependencies: (outputStream) =>
    return EngineOutput: EngineOutputFactory.createStreamEngineOutput(outputStream)

  createMessage: (topic, payload) =>
    metadata:
      flowId: @flowName
      instanceId: @instanceId
    message:
      payload: payload
      topic: topic
      fromUuid: 'engine-in-a-vat'

  messageEngine: (nodeId, message, topic, callback=->) =>
    startTime = Date.now()
    messages = []

    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration
    outputStream.on 'data', (envelope) =>
      debug MessageUtil.print envelope
      messages.push envelope

    newMessage = @createMessage topic, {message, from: nodeId}
    engine = new Engine @options, @getEngineDependencies(outputStream)
    engine.run newMessage, (error) =>
      outputStream.end()
      callback(error,messages)

    return outputStream

  subscribeToPulses: (callback)=>
    newMessage = @createMessage 'subscribe:pulse'
    engine = new Engine @options, @getEngineDependencies()
    engine.run newMessage, callback

  sendPing: (callback) =>
    messages = []

    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration
    outputStream.on 'data', (envelope) =>
      debug MessageUtil.print envelope
      messages.push envelope

    newMessage = @createMessage 'ping'
    engine = new Engine @options, @getEngineDependencies(outputStream)
    engine.run newMessage, (error) =>
      outputStream.end()
      callback error, messages

module.exports = EngineInAVat
