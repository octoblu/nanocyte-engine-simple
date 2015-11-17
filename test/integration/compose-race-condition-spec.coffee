_ = require 'lodash'
debug = require('debug')('compose-race-condition-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'ComposeRaceCondition', ->
  @timeout 15000
  describe 'when instantiated with a flow', ->
    beforeEach (done) ->
      flow = require './flows/compose-race-condition.json'
      @sut = new EngineInAVat flowName: 'compose-race-condition', flowData: flow
      @sut.initialize done

    describe 'when we send half of the object the compose node needs', ->
      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Handshake', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Shouldn't send a message to engine-debug basically", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 0

    describe 'when we send the other half of the object the compose node needs', ->
      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Handshake', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'High Five', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Should send one message to engine-debug basically", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 1

    describe 'when we send half of the object the compose node needs', ->
      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Handshake', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Shouldn't send a message to engine-debug basically", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 0

      describe 'when we then send the entire message the compose node needs', ->
        beforeEach (done) ->
          @messages = []
          @responseStream = @sut.triggerByName name: 'Both', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', done

        it "Shouldn't send a message to engine-debug basically", ->
          engineDebugs = _.filter @messages, (message) =>
            message.metadata.toNodeId == 'engine-debug'
          expect(engineDebugs.length).to.equal 1

    describe 'when we hit the both trigger', ->
      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Both', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Should send a message to engine-debug basically", ->
        engineDebugs = _.filter @messages, (message) =>
          message.metadata.toNodeId == 'engine-debug'
        expect(engineDebugs.length).to.equal 1
