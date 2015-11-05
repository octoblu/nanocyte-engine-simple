_ = require 'lodash'
debug = require('debug')('defer-error-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'defer-error', ->
  @timeout 600000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the defer-error', ->
      beforeEach (done) ->
        flow = require './flows/defer-error.json'
        @sut = new EngineInAVat flowName: 'defer-error', flowData: flow
        @sut.initialize done

      beforeEach (done) ->
        @messages = []
        @responseStream = @sut.triggerByName name: 'Trigger', message: 1
        @responseStream.on 'data', (msg) =>
          @messages.push msg

        @responseStream.on 'finish', done

      it "Should not crash", ->
        expect(@messages.length).to.equal 13
