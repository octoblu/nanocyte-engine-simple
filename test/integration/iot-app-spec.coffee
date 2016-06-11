_             = require 'lodash'
debug         = require('debug')('bluprint-spec')

EngineInAVat  = require '../../util/engine-in-a-vat/engine-in-a-vat'
shmock        = require 'shmock'

emptyFlow     = require './flows/empty-flow.json'
triggerFlow   = require './flows/trigger-to-debug.json'
broadcastFlow = require './flows/broadcast-species-greeting.json'

describe 'bluprint', ->
  @timeout 10000

  describe 'trigger-to-debug', ->
    before 'deploy the bluprint', (done) ->
      @iotAppEngine = new EngineInAVat
        flowName: 'bluprint', instanceId: '1.0.0', flowData: triggerFlow
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
        appId: 'bluprint'
        version: '1.0.0'
        configSchema: configSchema,
        config: config

      EngineInAVat.makeIotApp iotAppConfig, =>
        @sut = new EngineInAVat
          flowName: 'empty-flow', instanceId: 'hi', flowData: emptyFlow

        @sut.initialize =>
          @sut.messageEngine '1418a3c0-2dd2-11e6-9598-13e1d65cd653', {}, "button", (error, @messages) => done()

    it "Should send a message to the meshblu device", ->
      expect(@messages).to.containSubset [
        message: payload: msg: payload: ""
      ]

  describe 'changing values in species-greeting', ->

    before 'deploy the bluprint', (done) ->
      @iotAppEngine = new EngineInAVat
        flowName: 'bluprint', instanceId: '1.0.0', flowData: broadcastFlow

      @iotAppEngine.initialize done

    before 'deploy the empty', (done) ->
      configSchema =
        type: 'object'
        properties:
          greeting:
            type: 'string'
            "x-node-map": [
              {id: '12c6e770-2e77-11e6-9b9b-57e1c0397b24', property: 'compose.1.1'}
            ]

      config =
        greeting: 'hello'

      iotAppConfig =
        flowId: 'empty-flow'
        instanceId: 'hi'
        appId: 'bluprint'
        version: '1.0.0'
        configSchema: configSchema,
        config: config

      EngineInAVat.makeIotApp iotAppConfig, =>
        @sut = new EngineInAVat
          flowName: 'empty-flow', instanceId: 'hi', flowData: emptyFlow

        @sut.initialize =>
          @sut.messageEngine 'd79b32f0-2e76-11e6-9b9b-57e1c0397b24', {}, "button", (error, @messages) => done()

    it "Should template the message", ->
      expect(@messages).to.containSubset [
        message: payload: msg: text: "hello my glib-globs?"
      ]

    it "Should broadcast the message as the empty flow", ->
      expect(@messages).to.containSubset [
        config: uuid: "a66466af-26e6-4f67-a5d0-254262f54712"
      ]
