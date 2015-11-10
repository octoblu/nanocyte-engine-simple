_ = require 'lodash'
debug = require('debug')('function-to-function-loop')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'EqualsFigure8', ->
  @timeout 38000
  describe 'when instantiated with a flow', ->

    describe 'When instantiated with a flow', ->
      before (done)->
        flow = require './flows/equals-figure-8.json'
        @sut = new EngineInAVat flowName: 'equals-figure-8', flowData: flow
        @sut.initialize done

      before (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: count: 1
        @responseStream.on 'data', (msg) =>
          toNodeId = msg.metadata.toNodeId
          @messages.push toNodeId unless msg.metadata.fromNodeId == 'engine-pulse'

        @responseStream.on 'finish', done

      it "Should kill maybe around 1000 messages", ->
        expect(@messages.length).to.be.at.most 1100
