_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_TIMES = 100
DEBUG_MESSAGES = 8

describe 'OCTO-FLOWER', ->
  @timeout 60000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the OCTO-FLOWER', ->
      before (done) ->
        flow = require './flows/octo-flow.json'
        @sut = new EngineInAVat flowName: 'equals-train', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
        @times = 0
        @failure = false

        maybeFinish = =>
          @engineDebugs = _.filter @messages, (message) =>
            message.metadata.toNodeId == 'engine-debug'
          if @engineDebugs.length != DEBUG_MESSAGES
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

      it "Should send #{DEBUG_MESSAGES} messages to engine-debug", ->
        expect(@engineDebugs.length).to.equal DEBUG_MESSAGES
