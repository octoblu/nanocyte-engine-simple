_ = require 'lodash'
debug = require('debug')('equals-figure-8')
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

FLOW_TIMEOUT = 3000

describe 'EqualsFigure8', ->
  @timeout 30000
  describe 'when instantiated with a flow', =>

    before (done) =>

      @flow = require './flows/equals-figure-8.json'

      maybeFinish = =>
        debugs = _.filter @messages, (message) =>
          message.message.topic == 'debug'
        pulses = _.filter @messages, (message) =>
          message.message.topic == 'pulse'
        console.log @messages.length, pulses.length, debugs.length
        console.log JSON.stringify debugs, null, 2
        done()

      debug "initializing sut"
      @sut = new EngineInAVat
        flowName: "equals-figure-8"
        flowData: @flow
        flowTime:
          maxTime: FLOW_TIMEOUT

      @sut.initialize =>
        debug 'sut initialized'
        startTime = Date.now()
        @sut.triggerByName {name: 'Trigger', message: 1}, (@error, @messages) =>
          console.log 'got result from trigger!', @messages.length
          @messageTime = Date.now() - startTime
          maybeFinish()

    it "Should kill after #{FLOW_TIMEOUT} milliseconds", =>
      console.log (@messageTime)
      expect(Math.abs @messageTime - FLOW_TIMEOUT).to.be.at.most 100
