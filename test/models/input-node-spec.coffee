InputNode = require '../../src/models/input-node'

describe 'InputNode', ->
  beforeEach ->
    @triggerNode = require '../../src/models/wrapped-trigger-node'
    sinon.stub @triggerNode, 'onMessage'
    @router = onEnvelope: sinon.spy()

    @sut = new InputNode router: @router

  afterEach ->
    @triggerNode.onMessage.restore()

  describe 'onMessage', ->
    describe 'with a meshblu message', ->
      beforeEach ->
        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'
          payload:
            from: 'some-trigger-uuid'
            params:
              foo: 'bar'

      it 'should send a converted message to triggerNode', ->
        expect(@triggerNode.onMessage).to.have.been.calledWith
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'
          fromNodeId: 'meshblu-input'
          toNodeId: 'some-trigger-uuid'
          message: {params: {foo: 'bar'}}

      describe 'when the triggerNode yields an error', ->
        beforeEach ->
          @triggerNode.onMessage.yield new Error

        it 'should not call onEnvelope on the router with the envelope', ->
          expect(@router.onEnvelope).not.to.have.been.called

      describe 'when the triggerNode yields an envelope', ->
        beforeEach ->
          @triggerNode.onMessage.yield null, message: {some: 'message'}

        it 'should call onEnvelope on the router with a reconstructed envelope', ->
          expect(@router.onEnvelope).to.have.been.calledWith
            flowId:     'some-flow-uuid'
            instanceId: 'some-instance-uuid'
            fromNodeId: 'some-trigger-uuid'
            message:    some: 'message'

    describe 'with a different meshblu message', ->
      beforeEach ->
        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          payload:
            from: 'some-trigger-uuid'
            pep: 'step'

      it 'should send a converted message to triggerNode', ->
        expect(@triggerNode.onMessage).to.have.been.calledWith
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          fromNodeId: 'meshblu-input'
          toNodeId: 'some-trigger-uuid'
          message: {pep: 'step'}
