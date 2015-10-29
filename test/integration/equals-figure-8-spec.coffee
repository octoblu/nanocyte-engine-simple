_ = require 'lodash'
debug = require('debug')('function-to-function-loop')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'EqualsFigure8', ->
  @timeout 18000
  describe 'when instantiated with a flow', ->

    describe 'When instantiated with a flow', ->
      before (done)->
        flow = require './flows/equals-figure-8.json'
        @sut = new EngineInAVat flowName: 'equals-figure-8', flowData: flow
        @sut.initialize done

      it 'should exist', ->
        expect(@sut).to.exist

      before (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: count: 1
        @responseStream.on 'data', (msg) =>
          toNodeId = msg.metadata.toNodeId
          @messages.push toNodeId unless toNodeId == 'engine-pulse'

        @responseStream.on 'finish', done

      it "Should kill the flow after 1000 messages", ->
        expect(@messages.length).to.equal 1000