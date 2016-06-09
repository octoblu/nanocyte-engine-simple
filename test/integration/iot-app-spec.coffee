_ = require 'lodash'
debug = require('debug')('iot-app-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
shmock = require 'shmock'

describe 'iot-app', ->
  @timeout 10000
  before 'deploy the iot-app', (done) ->
    flow = require './flows/trigger-to-debug.json'
    @iotAppEngine = new EngineInAVat
      flowName: 'iot-app', instanceId: '1.0.0', flowData: flow
    @iotAppEngine.initialize done

  before 'deploy the empty', (done) ->
    flow = require './flows/empty-flow.json'
    configSchema =
      type: 'object'
      properties:
        whatKindaTriggerDoYouWant:
          type: 'string'
          "x-node-map": [
            {id: '1418a3c0-2dd2-11e6-9598-13e1d65cd653', property: 'payloadType'}
          ]

    config = whatKindaTriggerDoYouWant: 'date'
    iotAppConfig =
      flowId: 'empty-flow'
      instanceId: 'hi'
      appName: 'iot-app'
      version: '1.0.0'
      configSchema: configSchema,
      config: config

    EngineInAVat.makeIotApp iotAppConfig, =>
      @sut = new EngineInAVat
        flowName: 'empty-flow', instanceId: 'hi', flowData: flow

      @sut.initialize =>
        @sut.messageEngine '1418a3c0-2dd2-11e6-9598-13e1d65cd653', {}, "button", (error, @messages) => done()

  it "Should send a message to the meshblu device", ->
    console.log JSON.stringify @messages, null, 2
    expect(@messages).to.not.be.empty
