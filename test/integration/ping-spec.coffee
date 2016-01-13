_ = require 'lodash'
debug = require('debug')('ping-spec')
EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
{PassThrough} = require 'stream'

describe 'ping', ->
  @timeout 5000
  ERROR_COUNT = 1

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the interval', ->
      before (done) ->
        flow = require './flows/interval.json'
        @sut = new EngineInAVat flowName: 'ping', flowData: flow

        @messages = []
        @times = 0
        @failure = false

        @messages = []

        @sut.initialize =>
          @sut.sendPing (error, @envelopes) =>
            done()

      it "Should send messages to output", ->
        message = @envelopes[0].message
        expect(message.topic).to.equal 'pong'
