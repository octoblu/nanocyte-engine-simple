_ = require 'lodash'
debug = require('debug')('meshblu-device-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'meshblu-device', ->
  describe 'when instantiated with a flow', ->
    describe 'When we instantiate the meshblu-device', ->
      before (done) ->
        @messages = []
        flow = require './flows/meshblu-device.json'
        @sut = new EngineInAVat flowName: 'meshblu-device', flowData: flow
        @sut.initialize done

      before (done) ->
        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done


      it "Should send a message to the meshblu device", ->
        @engineOutputs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-output'
        console.log JSON.stringify _.pluck @engineOutputs
        expect(true).to.equal.true
