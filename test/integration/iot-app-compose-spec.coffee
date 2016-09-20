_             = require 'lodash'
debug         = require('debug')('iot-app-spec')

EngineInAVat  = require '../../util/engine-in-a-vat/engine-in-a-vat'
shmock        = require 'shmock'

emptyFlow     = require './flows/empty-flow.json'
emptyFlow2    = require './flows/empty-flow-2.json'
launchTheNukesFlow = require './flows/launch-the-nukes.json'

triggerA = 'c3c76bd0-2e95-11e6-b0c9-9338ae23bb3c'
triggerB = 'caa00bb0-2e95-11e6-b0c9-9338ae23bb3c'

describe 'iot-app-compose', ->
  @timeout 10000

  beforeEach 'config data', ->
    @configSchema  = type: 'object', properties: []
    @config        = {}

  beforeEach 'deploy the iot-app', (done) ->
    @iotAppEngine = new EngineInAVat
      flowName: 'launch-the-nukes', instanceId: '1.0.0', flowData: launchTheNukesFlow
    @iotAppEngine.initialize done

  afterEach 'clean up iot-app', (done) ->
    @iotAppEngine.cleanup done

  beforeEach 'deploy the canadian flow', (done) ->
    iotAppConfig =
      flowId: 'canada-nuke-launch-flow'
      instanceId: 'canadian-for-one'
      appId: 'launch-the-nukes'
      version: '1.0.0'
      configSchema: @configSchema,
      config: @config

    EngineInAVat.makeIotApp iotAppConfig, =>
      @canada = new EngineInAVat flowName: 'canada-nuke-launch-flow', instanceId: 'canadian-for-one', flowData: emptyFlow
      @canada.initialize done

  afterEach 'clean up Canadian flow', (done) ->
    @canada.cleanup done

  beforeEach 'deploy the second flow', (done) ->
    iotAppConfig =
      flowId: 'america-nuke-launch-flow'
      instanceId: 'we-like-nukes'
      appId: 'launch-the-nukes'
      version: '1.0.0'
      configSchema: @configSchema,
      config: @config

    EngineInAVat.makeIotApp iotAppConfig, =>
      @america = new EngineInAVat flowName: 'america-nuke-launch-flow', instanceId: 'we-like-nukes', flowData: emptyFlow2
      @america.initialize done

  afterEach 'clean up American flow', (done) ->
    @america.cleanup done

  describe 'when General A in Canada and General B in America approve of the launch', ->
    beforeEach (done) ->
      @canada.messageEngine triggerA, {}, "button", done

    beforeEach (done) ->
      @america.messageEngine triggerB, {}, "button", (error, @messages) => done()

    it "shouldn't launch the nukes", ->
      expect(@messages).not.to.containSubset [ message: payload: msg: text: "Gentlemen, we must LAUNCH THE NUKES!!!" ]

    describe 'when General A in America finally decides to nuke the rest of the world', ->
      beforeEach (done) ->
        @america.messageEngine triggerA, {}, "button", (error, @messages) => done()

      it "should launch the nukes", ->
        expect(@messages).to.containSubset [ message: payload: msg: text: "Gentlemen, we must LAUNCH THE NUKES!!!" ]


    describe 'when General B in Canada finally decides to nuke the rest of the world', ->
      beforeEach (done) ->
        @canada.messageEngine triggerB, {}, "button", (error, @messages) => done()

      it "should launch the nukes", ->
        expect(@messages).to.containSubset [ message: payload: msg: text: "Gentlemen, we must LAUNCH THE NUKES!!!" ]
