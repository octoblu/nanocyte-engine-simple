_ = require 'lodash'
debug = require('debug')('syntax-error-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'syntax-error', ->
  @timeout 60000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the syntax-error', ->
      before (done) ->
        flow = require './flows/defer-error.json'
        @sut = new EngineInAVat flowName: 'syntax-error', flowData: flow
        @sut.initialize done

      before (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) => @messages.push msg
        @responseStream.on 'finish', done

      it "Should not crash", ->
        expect(@messages.length).to.equal 9
