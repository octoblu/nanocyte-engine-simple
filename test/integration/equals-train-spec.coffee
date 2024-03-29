_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
MAX_TIMES = 1
DEBUG_TIMES= 12
describe 'EqualsTrain', ->
  @timeout 60000
  describe 'when instantiated with a flow', =>

    describe 'When we instantiate the engine with a flow with 17 equals nodes and a trigger', =>
      before (done) =>
        flow = require './flows/smaller-equals-train.json'
        @sut = new EngineInAVat
          flowName: 'equals-train'
          flowData: flow
          redlock:
            retryDelay: 0

        @sut.initialize done

      before (done) =>
        @times = 0
        @failure = false

        maybeFinish = (@error,@messages)=>
          @engineDebugs = _.filter @messages, (message) =>
            message.message.topic == 'debug'
          if @engineDebugs.length != DEBUG_TIMES
            @failure = true
            return done()
          return done() if @times == MAX_TIMES
          testIt()

        testIt = =>
          @times++
          @messages = []
          @sut.triggerByName {name: 'Trigger', message: 1}, maybeFinish

        testIt()

      it "Should send 6 messages to engine-debug", =>
        expect(@engineDebugs.length).to.equal DEBUG_TIMES

      it "Should have passed #{MAX_TIMES} times", =>
        expect(@times).to.equal MAX_TIMES
