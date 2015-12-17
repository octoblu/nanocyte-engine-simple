_ = require 'lodash'
debug = require('debug')('demultiplex-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'demultiplex', ->
  @timeout 10000

  describe 'when instantiated with a flow', =>

    describe 'When we instantiate the demultiplex', =>
      before (done) =>
        flow = require './flows/demultiplex.json'
        @sut = new EngineInAVat flowName: 'demultiplex', flowData: flow
        @sut.initialize =>
          @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) =>
            done()

      it "Should send the correct messages to engine-debug", =>
        debugs = _.filter @messages, (message) =>
          message.message.topic == 'debug'
        pulses = _.filter @messages, (message) =>
          message.message.topic == 'pulse'
        msgs = _.map debugs, (debug) => debug.message.payload.msg
        expect(@messages.length).to.equal 74
        expect(debugs.length).to.equal 24
        expect(pulses.length).to.equal 50
        expect(msgs.join('')).to.equal 'such amazing demultiplex'
