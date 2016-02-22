_ = require 'lodash'
debug = require('debug')('demultiplex-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'demultiplex', ->
  @timeout 10000

  describe 'when instantiated with a flow', =>

    describe 'When we instantiate the demultiplex', =>
      before (done) =>
        flow = require './flows/demultiplex.json'
        @sut = new EngineInAVat
          flowName: 'demultiplex'
          flowData: flow
          redlock:
            retryDelay: 0

        @sut.initialize =>
          @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) =>
            done()

      it "Should send the correct messages to engine-debug", =>
        debugs = _.filter @messages, (message) =>
          message.message.topic == 'debug'
        pulses = _.filter @messages, (message) =>
          message.message.topic == 'pulse'
        msgs = _.map debugs, (debug) => debug.message.payload.msg
        expect(@messages.length).to.equal 302
        expect(debugs.length).to.equal 100
        expect(pulses.length).to.equal 202
        expect(msgs.join('')).to.equal _.times(100).join('')
