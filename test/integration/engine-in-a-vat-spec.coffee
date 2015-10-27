EngineInAVat = require '../../util/engine-in-a-vat/engine-in-a-vat'
xdescribe 'EngineInAVat', ->
  @timeout 5000
  describe 'when instantiated with a flow', ->
    beforeEach (done)->
      flow = require './flows/compose-race-condition.json'
      @sut = new EngineInAVat flowName: 'compose-race-condition', flowData: flow
      @sut.initialize done

    it 'should exist', ->
      expect(@sut).to.exist

    describe 'when we trigger the engine with a trigger', ->
      beforeEach (done) ->
        @responseStream = @sut.triggerByName name: 'Handshake', message: 1
        @responseStream.on 'data', (msg) => console.log 'data', msg
      it 'should get here', ->
        expect(true).to.be.true
