{Transform,PassThrough} = require 'stream'
_                       = require 'lodash'
redis                   = require 'ioredis'
debug                   = require('debug')('engine-in-a-vat')
uuid                    = require 'node-uuid'
mongojs                 = require 'mongojs'
Datastore               = require 'meshblu-core-datastore'
ConfigurationGenerator  = require 'nanocyte-configuration-generator'
ConfigurationSaver      = require 'nanocyte-configuration-saver-redis'
Engine                  = require '../../src/models/engine'

EngineOutputFactory     = require './engine-output-factory'
AddNodeInfoStream       = require './add-node-info-stream'
MessageUtil             = require './message-util'

class VatChannelConfig
  fetch: (callback) => callback null, {}
  get: => {}
  update: (callback) => callback null

class EngineInAVat
  constructor: (@options) ->
    @options.instanceId ?= uuid.v4()
    {@flowName, @flowData, @instanceId, @meshbluJSON, @version} = @options
    @meshbluJSON ?= {}
    @triggers = @findTriggers()

    @configurationGenerator = @_createConfigurationGenerator()
    @configurationSaver     = @_createConfigurationSaver()

    debug 'created an EngineInAVat with flowName', @flowName, 'instanceId', @instanceId

  _createConfigurationGenerator: =>
    return new ConfigurationGenerator {@meshbluJSON}, channelConfig: new VatChannelConfig

  _createConfigurationSaver: =>
      client    = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD, dropBufferSupport: true
      db        = mongojs 'localhost/engine-in-a-vat', ['deploys']
      datastore = new Datastore database: db, collection: 'deploys'

      return new ConfigurationSaver {client, datastore}

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

  publishIotApp: (callback=->) =>
    debug 'publishing IoT App'
    @configurationGenerator.configure flowData: @flowData, userData: {}, (error, configuration) =>
      return console.error "config generator had an error!", error if error?
      debug "publishIotApp configured"
      @configuration = configuration
      @configurationSaver.saveIotApp appId: @flowName, version: @version, flowData: configuration, (error, result)=>
        return console.error "config saver had an error!", error if error?
        debug "publishIotApp saved"
        callback()

  @makeIotApp: ({flowId, instanceId, appId, version, configSchema, config}, callback) =>
    client =
      redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD, dropBufferSupport: true

    client.hset flowId, "#{instanceId}/bluprint/config", JSON.stringify({appId, version, configSchema, config}), callback

  getEngineDependencies: (outputStream) =>
    return EngineOutput: EngineOutputFactory.createStreamEngineOutput(outputStream)

  createMessage: (topic, payload) =>
    metadata:
      flowId: @flowName
      instanceId: @instanceId
      toNodeId: 'engine-input'
      metadata:
        route: []
        forwardedRoutes: []
    message:
      payload: payload
      topic: topic
      fromUuid: 'engine-in-a-vat'

  messageEngine: (nodeId, otherStuff, topic, callback=->) =>
    startTime = Date.now()
    messages = []

    outputStream = new AddNodeInfoStream flowData: @flowData, nanocyteConfig: @configuration
    outputStream.on 'data', (envelope) =>
      debug MessageUtil.print envelope
      messages.push envelope

    newMessage = @createMessage topic, _.extend {from: nodeId}, otherStuff
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
