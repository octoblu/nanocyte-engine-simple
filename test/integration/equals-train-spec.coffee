_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'EqualsTrain', ->
  @timeout 30000
  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the engine with a flow with 17 equals nodes and a trigger', ->
      before (done) ->
        flow = require './flows/equals-train.json'
        @sut = new EngineInAVat flowName: 'equals-train', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
        @times = 0
        @failure = false
        @MAX_TIMES = 100

        maybeFinish = =>
          @engineDebugs = _.filter @messages, (message) =>
            message.metadata.toNodeId == 'engine-debug'
          if @engineDebugs.length != 6
            @failure = true
            return done()
          return done() if @times == @MAX_TIMES
          testIt()

        testIt = =>
          @times++
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', maybeFinish

        testIt()

      it "Should have passed #{@MAX_TIMES} times", ->
        expect(@times).to.equal @MAX_TIMES

      it "Should send 6 messages to engine-debug", ->
        expect(@engineDebugs.length).to.equal 6
