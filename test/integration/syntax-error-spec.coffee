_ = require 'lodash'
debug = require('debug')('syntax-error-spec')
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'syntax-error', ->
  @timeout 3000
  ERROR_COUNT = 1

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
          # console.log JSON.stringify @messages, null, 2
          @engineErrors = _.filter @messages, (message) =>
            message.metadata.msgType == 'error'
          done()

      it "Should send an error message to engine-debug", ->
        expect(@engineErrors.length).to.equal ERROR_COUNT
        expect(@engineErrors[0].message.payload.msg).to.equal "fdkjshfksdjhfdskjh is not defined"
        expect(@engineErrors[0].message.payload.node).to.equal "69226c50-7ea7-11e5-b898-cf755933df9a"
