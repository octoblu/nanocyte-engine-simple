_ = require 'lodash'
debug = require('debug')('iot-app-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
shmock = require 'shmock'

flow = require './flows/empty-flow.json'

describe 'iot-app', ->
  @timeout 10000

  describe 'trigger-to-debug', ->
    before 'deploy the iot-app', (done) ->
      flow = require './flows/trigger-to-debug.json'
      @iotAppEngine = new EngineInAVat
        flowName: 'iot-app', instanceId: '1.0.0', flowData: flow
      @iotAppEngine.initialize done

    before 'deploy the empty', (done) ->
      configSchema =
        type: 'object'
        properties:
          whatKindaTriggerDoYouWant:
            type: 'string'
            "x-node-map": [
              {id: '1418a3c0-2dd2-11e6-9598-13e1d65cd653', property: 'payloadType'}
            ]

      config = whatKindaTriggerDoYouWant: 'none'
      iotAppConfig =
        flowId: 'empty-flow'
        instanceId: 'hi'
        appId: 'iot-app'
        version: '1.0.0'
        configSchema: configSchema,
        config: config

      EngineInAVat.makeIotApp iotAppConfig, =>
        @sut = new EngineInAVat
          flowName: 'empty-flow', instanceId: 'hi', flowData: flow

        @sut.initialize =>
          @sut.messageEngine '1418a3c0-2dd2-11e6-9598-13e1d65cd653', {}, "button", (error, @messages) => done()

    it "Should send a message to the meshblu device", ->
      expect(@messages).to.containSubset [
        message: payload: msg: payload: ""
      ]

  describe 'changing values in species-greeting', ->
    before 'deploy the iot-app', (done) ->
      flow = require './flows/broadcast-species-greeting.json'
      @iotAppEngine = new EngineInAVat
        flowName: 'iot-app', instanceId: '1.0.0', flowData: flow
      @iotAppEngine.initialize done

    before 'deploy the empty', (done) ->
      configSchema =
        type: 'object'
        properties:
          greeting:
            type: 'string'
            "x-node-map": [
              {id: '46b72292-e288-4bc4-855c-019fb241c1ad', property: 'compose.1.1'}
            ]

      config =
        greeting: 'hello'

      iotAppConfig =
        flowId: 'empty-flow'
        instanceId: 'hi'
        appId: 'iot-app'
        version: '1.0.0'
        configSchema: configSchema,
        config: config

      EngineInAVat.makeIotApp iotAppConfig, =>
        @sut = new EngineInAVat
          flowName: 'empty-flow', instanceId: 'hi', flowData: flow

        @sut.initialize =>
          @sut.messageEngine '1418a3c0-2dd2-11e6-9598-13e1d65cd653', {}, "button", (error, @messages) => done()

    xit "Should send a message to the meshblu device", ->
      expect(@messages).to.containSubset [
        message: payload: msg: payload: ""
      ]
