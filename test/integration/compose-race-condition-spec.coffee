_ = require 'lodash'
debug = require('debug')('compose-race-condition-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'ComposeRaceCondition', ->
  @timeout 15000
  describe 'when instantiated with a flow', =>
    before (done) =>
      flow = require './flows/compose-race-condition.json'
      @sut = new EngineInAVat flowName: 'compose-race-condition', flowData: flow
      @sut.initialize done
      @getDebugs = (messages=@messages) =>
        return _.filter messages, (message) =>
          message.message.topic == 'debug'

    describe 'when we send half of the object the compose node needs', =>
      before (done) =>
        @sut.triggerByName {name: 'Handshake', message: 1}, (error, @messages) => done()

      it "Shouldn't send a message to engine-debug basically", =>
        expect(@getDebugs().length).to.equal 0

    describe 'when we send the other half of the object the compose node needs', =>
      before (done) =>
        @sut.triggerByName {name: 'Handshake', message: 1}, (error, @handshakeMessages) => done()

      before (done) =>
        @sut.triggerByName {name: 'High Five', message: 1}, (error, @highFiveMessages) => done()

      it "Should send one message to engine-debug basically", =>
        @messages = @handshakeMessages.concat @highFiveMessages
        expect(@getDebugs().length).to.equal 1

    describe 'when we send half of the object the compose node needs', =>
      before (done) =>
        @sut.triggerByName {name: 'Handshake', message: 1}, (error, @messages) => done()

      it "Shouldn't send a message to engine-debug basically", =>
        expect(@getDebugs().length).to.equal 0

      describe 'when we then send the entire message the compose node needs', =>
        before (done) =>
          @sut.triggerByName {name: 'Both', message: 1}, (error, @messages) => done()

        it "Shouldn't send an extra message to engine-debug basically", =>
          expect(@getDebugs().length).to.equal 1

    describe 'when we hit the both trigger', =>
      before (done) =>
        @sut.triggerByName {name: 'Both', message: 1}, (error, @messages) => done()

      it "Should send a message to engine-debug basically", =>
        expect(@getDebugs().length).to.equal 1
