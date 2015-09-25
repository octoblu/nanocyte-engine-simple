InputNode = require '../../src/models/input-node'

describe 'InputNode', ->
  beforeEach ->
    @router = onEnvelope: sinon.spy()
    @sut = new InputNode router: @router

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

      it 'should send a converted message to the router', ->
        expect(@router.onEnvelope).to.have.been.calledWith
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'
          fromNodeId: 'some-trigger-uuid'
          message: {params: {foo: 'bar'}}

    describe 'with a different meshblu message', ->
      beforeEach ->
        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          payload:
            from: 'some-other-trigger-uuid'
            pep: 'step'

      it 'should send a converted message to router', ->
        expect(@router.onEnvelope).to.have.been.calledWith
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          fromNodeId: 'some-other-trigger-uuid'
          message: {pep: 'step'}

    describe 'with a meshblu message thats missing a payload', ->
      beforeEach ->
        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          fromUuid: 'some-node-uuid'

      it 'should use the fromUuid as the nodeId', ->
        expect(@router.onEnvelope).to.have.been.calledWith
          flowId: 'some-flow-uuid'
          instanceId: 'some-other-instance-uuid'
          fromNodeId: 'some-node-uuid'
          message: {}

    describe 'with a meshblu message thats missing a from', ->
      beforeEach ->
        try
          @sut.onMessage
            topic: 'button'
            devices: ['some-flow-uuid']
            flowId: 'some-flow-uuid'
            instanceId: 'some-other-instance-uuid'
            payload:
              pep: 'step'
        catch error
          @error = error

      it 'should not throw an exception', ->
        expect(@error).not.to.exist

      it 'should not throw an exception', ->
        expect(@router.onEnvelope).not.to.have.been.called
