_ = require 'lodash'
debug = require('debug')('meshblu-device-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'meshblu-device', ->
  describe 'when instantiated with a flow', ->
    describe 'When we instantiate the meshblu-device', ->
      before (done) ->
        flow = require './flows/meshblu-device.json'
        @sut = new EngineInAVat flowName: 'meshblu-device', flowData: flow
        @sut.initialize =>
          @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) => done()

      it "Should send a message to the meshblu device", ->
        expect(@error).to.not.exist
        @meshbluOutputs = _.filter @messages, (message) =>
          _.isEqual message.message.devices, ["78c216fd-5054-455d-a91e-c08da0383b72"]
        expect(@meshbluOutputs.length).to.equal 1
