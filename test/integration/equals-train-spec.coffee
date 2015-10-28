_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'EngineInAVat', ->
  @timeout 5000
  describe 'when instantiated with a flow', ->

    describe 'when we send half of the object the compose node needs', ->
      before (done) ->
        flow = require './flows/equals-train.json'
        @sut = new EngineInAVat flowName: 'compose-race-condition', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Should send a message to engine-debug", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 2
