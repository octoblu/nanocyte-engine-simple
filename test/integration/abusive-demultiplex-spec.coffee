_ = require 'lodash'
debug = require('debug')('demultiplex-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'abusive demultiplex', ->
  @timeout 10000
  ERROR_COUNT = 1

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the demultiplex', ->
      before (done) ->
        flow = require './flows/abusive-demultiplex.json'
        @sut = new EngineInAVat
          flowName: 'demultiplex'
          flowData: flow
          redlock:
            retryDelay: 0

        @sut.initialize =>
          @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) =>
            @engineErrors = _.filter @messages, (message) =>
              message?.message?.payload?.msgType == 'error'
            done()

      it "Should send an error message to engine-debug", ->
        expect(@engineErrors.length).to.equal ERROR_COUNT
        expect(@engineErrors[0].message.payload.msg).to.equal "messageCounter.max is too high!"
