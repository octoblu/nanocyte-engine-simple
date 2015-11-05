_ = require 'lodash'
debug = require('debug')('demo-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_TIMES = 50
DEBUG_MESSAGES = 2
xdescribe 'DemoFlow', ->
  @timeout 1200000
  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the engine with the demo flow', ->
      before (done) ->
        flow = require './flows/demo.json'
        @sut = new EngineInAVat flowName: 'demo', flowData: flow
        @sut.initialize done

      before (done) ->
        @times = 0
        @failure = false

        maybeFinish = =>
          EngineInAVat.printMessageStats @messages

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
          @responseStream = @sut.triggerByName name: 'trigger', message: 1
          @responseStream.on 'data', (msg) =>
            @messages = @messages.concat @sut.unbatchMessages msg

          @responseStream.on 'finish', maybeFinish

        testIt()

      it "Should have passed #{MAX_TIMES} times", ->
        expect(@times).to.equal MAX_TIMES

      it "Should send #{DEBUG_MESSAGES} messages to engine-debug", ->
        expect(@engineDebugs.length).to.equal DEBUG_MESSAGES
