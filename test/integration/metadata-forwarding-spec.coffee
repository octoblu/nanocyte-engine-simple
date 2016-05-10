_ = require 'lodash'
shmock = require 'shmock'
{afterEach,beforeEach,context,describe,it} = global
{expect} = require 'chai'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'metadata-forwarding', ->
  beforeEach (done) ->
    @meshblu = shmock done
    @searchRequest = @meshblu.post('/search/devices')

  afterEach (done) ->
    @meshblu.close done

  beforeEach ->
    @meshbluJSON =
      uuid: 'uuid'
      token: 'token'
      server: 'localhost'
      port: @meshblu.address().port

  beforeEach (done) ->
    flow = require './flows/metadata-forwarding-flow.json'

    @metadataDeviceUuid = "4a275371-03b1-458c-8b3b-6d756c567202"
    @noMetadataDeviceUuid = "b2e17d9f-0b2c-48a8-88fb-325bc927c5a6"

    @searchRequest.reply 201, [uuid: @metadataDeviceUuid]
    @sut = new EngineInAVat
      flowName: 'metadata-forwarding', flowData: flow, meshbluJSON: @meshbluJSON
    @sut.initialize done

  beforeEach (done) ->
    @sut.triggerByName {name: 'Trigger', message: 1}, (error, @messages) => done()

  context "A message to a device that doesn't want flow metadata", ->
    beforeEach ->
      {@message} = _.find @messages, ({message}) =>
        _.includes message.devices, @noMetadataDeviceUuid

    it "Should not send a message to the device that does not want metadata", ->
      expect(@message.metadata).not.to.exist

  context "A message to a device that wants flow metadata", ->
    beforeEach ->
      {@message} = _.find @messages, ({message}) =>
        _.includes message.devices, @metadataDeviceUuid

    it "Should send a message to the device that does want metadata", ->
      expect(@message.metadata).to.exist
