_ = require 'lodash'
debug = require('debug')('syntax-error-spec')
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'syntax-error', ->
  @timeout 5000
  ERROR_COUNT = 1

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the syntax-error', ->
      before (done) ->
        flow = require './flows/syntax-error.json'
        @sut = new EngineInAVat flowName: 'syntax-error', flowData: flow

        @messages = []
        @times = 0
        @failure = false

        @messages = []

        @sut.initialize =>
          @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) =>
            @engineErrors = _.filter @messages, (message) =>
              message?.message?.payload?.msgType == 'error'
            # console.log JSON.stringify @messages, null, 2
            # console.log JSON.stringify @engineErrors, null, 2
            done()

      it "Should send an error message to engine-debug", ->
        expect(@engineErrors.length).to.equal ERROR_COUNT
        expect(@engineErrors[0].message.payload.msg).to.equal "fdkjshfksdjhfdskjh is not defined"
        expect(@engineErrors[0].message.payload.node).to.equal "69226c50-7ea7-11e5-b898-cf755933df9a"
