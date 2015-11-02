_ = require 'lodash'
debug = require('debug')('error-async-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'error-async', ->
  @timeout 60000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the error-async', ->
      before (done) ->
        flow = require './flows/error-async.json'
        @sut = new EngineInAVat flowName: 'error-async', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', done

      it "Should exist", ->
        expect(true).to.equal true

      xit "Should send messages to engine-debug", ->
        expect(@engineDebugs.length).to.equal DEBUG_MESSAGES
