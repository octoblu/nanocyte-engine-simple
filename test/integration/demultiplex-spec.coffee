_ = require 'lodash'
debug = require('debug')('demultiplex-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

describe 'demultiplex', ->
  @timeout 10000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the demultiplex', ->
      before (done) ->
        flow = require './flows/demultiplex.json'
        @sut = new EngineInAVat flowName: 'demultiplex', flowData: flow
        @sut.initialize done

      before (done) ->
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', done

      it "Should send messages to engine-debug", ->
        expect(@messages.length).to.equal 28
