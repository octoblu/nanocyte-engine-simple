_ = require 'lodash'
debug = require('debug')('equals-figure-8')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
MAX_TIMES = 10
DEBUG_TIMES= 6
xdescribe 'EqualsFigure8', ->
  @timeout 3000
  describe 'when instantiated with a flow', ->

    beforeEach ->
      @flow = require './flows/smaller-equals-train.json'

    beforeEach (done) ->
      @times = 0
      @failure = false

      maybeFinish = =>
        @engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        # if @engineDebugs.length != DEBUG_TIMES
        #   @failure = true
        #   return done()
        return done() if @times == MAX_TIMES
        testIt()

      testIt = =>
        debug "initializing sut #{@times}"
        debug process.memoryUsage()
        @sut = new EngineInAVat flowName: 'equals-train', flowData: @flow
        @sut.initialize =>
          debug 'sut initialized'
          @times++
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', maybeFinish

      testIt()

    it "Should kill maybe around 1000 messages", ->
      expect(@messages.length).to.be.at.most 1100
