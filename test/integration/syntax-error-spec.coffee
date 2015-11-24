_ = require 'lodash'
debug = require('debug')('syntax-error-spec')
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'syntax-error', ->
  @timeout 3000
  ERROR_COUNT = 3

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the syntax-error', ->
      before (done) ->
        flow = require './flows/syntax-error.json'
        @sut = new EngineInAVat flowName: 'syntax-error', flowData: flow
        @sut.initialize done

      before (done) ->
        @messages = []
        @times = 0
        @failure = false

        @messages = []

        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', =>
          console.log @messages
          @engineErrors = _.filter @messages, (message) =>
            message.metadata.msgType == 'error'

          done()

      it "Should send 2 error message to engine-debug", ->
        expect(@engineErrors.length).to.equal ERROR_COUNT
