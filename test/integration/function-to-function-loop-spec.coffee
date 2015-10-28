_ = require 'lodash'
debug = require('debug')('function-to-function-loop')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'EngineInAVat', ->
  @timeout 18000
  describe 'when instantiated with a flow', ->

    describe 'when we send half of the object the compose node needs', ->
      before (done)->
        flow = require './flows/function-to-function-loop.json'
        @sut = new EngineInAVat flowName: 'compose-race-condition', flowData: flow
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

      it "Shouldn't send a message to engine-debug basically", ->
        expect(@messages.length).to.equal 300
