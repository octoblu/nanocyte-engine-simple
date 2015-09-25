InputNode = require '../../src/models/input-node'

describe 'InputNode', ->
  beforeEach ->
    @router    = onEnvelope: sinon.spy()
    @datastore = get: sinon.stub()
    @sut = new InputNode {}, router: @router, datastore: @datastore

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
          fromUuid: 'some-device-uuid'

      it 'should call datastore.get on the engine-input', ->
        expect(@datastore.get).to.have.been.calledWith 'some-flow-uuid/some-other-instance-uuid/engine-input/config'

      describe 'when the engine-input config contains the fromUuid', ->
        beforeEach ->
          @datastore.get.yield null,
            'some-device-uuid':
              nodeId: 'some-internal-node-uuid'

        it 'should use the fromUuid as the nodeId', ->
          expect(@router.onEnvelope).to.have.been.calledWith
            flowId: 'some-flow-uuid'
            instanceId: 'some-other-instance-uuid'
            fromNodeId: 'some-internal-node-uuid'
            message: {}

      describe 'when the engine-input config doesn\'t contain the fromUuid', ->
        beforeEach ->
          @datastore.get.yield null, {}

        it 'should not call router.onEnvelope', ->
          expect(@router.onEnvelope).not.to.have.been.called

      describe 'when the engine-input config yields an error', ->
        beforeEach ->
          @datastore.get.yield new Error 'DB went on vacation'

        it 'should not call router.onEnvelope', ->
          expect(@router.onEnvelope).not.to.have.been.called

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
