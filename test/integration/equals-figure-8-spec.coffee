_ = require 'lodash'
debug = require('debug')('equals-figure-8')
async = require 'async'
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

ASYNC_TIMES = 60
FLOW_TIMEOUT = 120000
FLOW_TIMEOUT_CHECK = (FLOW_TIMEOUT/ASYNC_TIMES)*5

describe 'EqualsFigure8', ->
  @timeout FLOW_TIMEOUT_CHECK*2
  describe 'when instantiated with a flow', =>

    before (done) =>

      @flow = require './flows/equals-figure-8.json'
      @flowName = "equals-figure-8-#{Date.now()}"
      @messages = []

      maybeFinish = =>
        @debugs = _.filter @messages, (message) =>
          message.message.topic == 'debug'
        @pulses = _.filter @messages, (message) =>
          message.message.topic == 'pulse'
        # console.log @messages.length, @pulses.length, @debugs.length
        # console.log JSON.stringify @debugs[0], null, 2
        # console.log (@messageTime)
        done()

      debug "initializing sut"
      @sut = new EngineInAVat
        flowName: @flowName
        flowData: @flow
        flowTime:
          maxTime: FLOW_TIMEOUT
        redlock:
          retryDelay: 0

      @sut.initialize =>
        debug 'sut initialized'
        startTime = Date.now()
        async.times ASYNC_TIMES, (n, next) =>
          debug "sending Throttle message ##{n}"
          @sut.triggerByName {name: 'Trigger', message: 1}, (error, messages) =>
            @messages = @messages.concat(messages)
            next()
        , =>
          @messageTime = Date.now() - startTime
          maybeFinish()

    it "Should kill before #{FLOW_TIMEOUT_CHECK/1000} seconds", =>
      errorString = "flow violated max flow-time of #{FLOW_TIMEOUT}ms (#{@flowName})"
      expect(@messageTime).to.be.at.most FLOW_TIMEOUT_CHECK
      expect(@debugs.length).to.equal ASYNC_TIMES
      expect(@debugs[0].message.payload.msg.startsWith errorString).to.equal true
