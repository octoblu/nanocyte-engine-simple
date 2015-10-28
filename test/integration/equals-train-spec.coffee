_ = require 'lodash'
debug = require('debug')('equals-train-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'EqualsTrain', ->
  @timeout 5000
  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the engine with a flow with 17 equals nodes and a trigger', ->
      before (done) ->
        flow = require './flows/equals-train.json'
        @sut = new EngineInAVat flowName: 'equals-train', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Should send 2 messages to engine-debug", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 2
