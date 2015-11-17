_ = require 'lodash'
debug = require('debug')('demultiplex-spec')

EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'

xdescribe 'demultiplex', ->
  @timeout 60000

  describe 'when instantiated with a flow', ->

    describe 'When we instantiate the demultiplex', ->
      beforeEach (done) ->
        flow = require './flows/demultiplex.json'
        @sut = new EngineInAVat flowName: 'demultiplex', flowData: flow
        @sut.initialize done

      beforeEach (done) ->
          startTime = Date.now()
          @messages = []
          @responseStream = @sut.triggerByName name: 'Trigger', message: 1
          @responseStream.on 'data', (msg) => @messages.push msg
          @responseStream.on 'finish', =>
            @elapsedTime = Date.now() - startTime
            done()

      it "Should send messages to engine-debug", ->
        expect(@elapsedTime).to.be.at.least 30000
        expect(@elapsedTime).to.be.at.most 45000
