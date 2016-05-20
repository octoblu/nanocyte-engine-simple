_ = require 'lodash'
debug = require('debug')('compose-dynamic-keys-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
describe 'ComposeRaceCondition', ->
  @timeout 15000
  describe 'when instantiated with a flow', =>
    before (done) =>
      flow = require './flows/compose-dynamic-keys.json'
      @sut = new EngineInAVat flowName: 'compose-dynamic-keys', flowData: flow
      @sut.initialize done
      @getDebugs = (messages=@messages) =>
        return _.filter messages, (message) =>
          message.message.topic == 'debug'

    describe 'when we send half of the object the compose node needs', =>
      before (done) =>
        @sut.triggerByName {name: 'Tigger', message: 1}, (error, @messages) => done()

      it "Shouldn't send a message to engine-debug basically", =>
        expect(@getDebugs()).to.containSubset [
          message:
            payload:
              msg:
                'thumb-war': 'static, I guess'
        ]
