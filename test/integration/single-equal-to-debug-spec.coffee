_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

MAX_MESSAGES = 4
DEBUG_MESSAGES = 1

describe 'single-equal-to-debug', ->
  @timeout 60000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the single-equal-to-debug', ->
      beforeEach (done) ->
        flow = require './flows/single-equal-to-debug.json'
        @sut = new EngineInAVat flowName: 'single-equal-to-debug', flowData: flow
        @sut.initialize done

      beforeEach (done) ->
        maybeFinish = (error, @messages) =>
          @engineDebugs = _.filter @messages, (message) =>
            message?.message?.topic == 'debug'
          done()

        @sut.triggerByName {name: 'Trigger', message: 1}, maybeFinish

      it "Should send #{MAX_MESSAGES} messages", ->
        expect(@messages.length).to.equal MAX_MESSAGES

      it "Should send #{DEBUG_MESSAGES} messages to engine-debug", ->
        expect(@engineDebugs.length).to.equal DEBUG_MESSAGES
