_ = require 'lodash'
debug = require('debug')('error-async-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'error-async', ->
  @timeout 60000
  MAX_TIMES = 10
  ERROR_COUNT = 2

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the error-async', ->
      before (done) ->
        flow = require './flows/error-async.json'
        @sut = new EngineInAVat flowName: 'error-async', flowData: flow
        @sut.initialize done

      before (done) ->
        @messages = []
        @times = 0
        @failure = false

        maybeFinish = =>
          @engineErrors = _.filter @messages, (message) =>
            message.metadata.msgType == 'error'
          if @engineErrors.length != ERROR_COUNT
            @failure = true
            return done()
          return done() if @times == MAX_TIMES
          testIt()

        testIt = =>
          @times++
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', maybeFinish

        testIt()

      it "Should have passed #{MAX_TIMES} times", ->
        expect(@times).to.equal MAX_TIMES

      it "Should send 1 error message to engine-debug", ->
        expect(@engineErrors.length).to.equal ERROR_COUNT
