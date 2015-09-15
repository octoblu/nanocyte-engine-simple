NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'

describe 'WrapperFactory', ->
  describe '->onEnvelope', ->
    beforeEach ->
      @mahNodeOnMessage = sinon.stub().yields()
      @MahNode = sinon.spy =>
        onMessage: @mahNodeOnMessage

      @sut = new NanocyteNodeWrapper nodeClass: @MahNode

    describe 'when called with an envelope', ->
      beforeEach (done) ->
        @sut.onEnvelope config: {contains: 'config'}, data: {is: 'data'}, message: {foo: 'bar'}, done

      it 'should instantiate MahNode', ->
        expect(@MahNode).to.have.been.calledWithNew
        expect(@MahNode).to.have.been.calledWith {contains: 'config'}, {is: 'data'}

      it 'should call onMessage on MahNode', ->
        expect(@mahNodeOnMessage).to.have.been.called
