Router = require '../../src/models/router'

describe 'Router', ->
  beforeEach ->
    @datastore = get: sinon.stub()

  describe 'onEnvelope', ->
    describe 'when the nodeAssembler returns some nodes', ->
      beforeEach ->
        @debugNodeOnEnvelope = debugNodeOnEnvelope = sinon.spy()

        class NodeAssembler
          assembleNodes: =>
            'nanocyte-node-debug': onEnvelope: debugNodeOnEnvelope

        @nodeAssembler = new NodeAssembler
        sinon.spy @nodeAssembler, 'assembleNodes'
        @sut = new Router datastore: @datastore, nodeAssembler: @nodeAssembler

      describe 'when the datastore yields nothing for the flowId', ->
        beforeEach ->
          @datastore.get.yields null, null

        describe 'when given an envelope', ->
          it 'should not be a little sissy about it', ->
            theCall = => @sut.onEnvelope
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              message: 12455663
            expect(theCall).not.to.throw()


      describe 'when the trigger node is wired to a nonexistent node', ->
        beforeEach ->
          @datastore.get.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']

        it 'should not be a little sissy about it', ->
          theCall = => @sut.onEnvelope
            fromNodeId: 'some-trigger-uuid'
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the trigger node doesnt exist', ->
        beforeEach ->
          @datastore.get.yields null, {}

        it 'should not be a little sissy about it', ->
          theCall = => @sut.onEnvelope
            fromNodeId: 'some-trigger-uuid'
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the trigger node is wired to a debug node', ->
        beforeEach ->
          @datastore.get.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []

        describe 'when given an envelope', ->
          beforeEach ->
            @sut.onEnvelope
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              message: 12455663

          it 'should call datastore.get', ->
            expect(@datastore.get).to.have.been.calledWith 'some-flow-uuid/instance-uuid/router/config'

          it 'should call onEnvelope in the debugNode from assembleNodes one time', ->
            expect(@debugNodeOnEnvelope).to.have.been.calledOnce

          it 'should call onEnvelope in the debugNode with the envelope', ->
            expect(@debugNodeOnEnvelope).to.have.been.calledWith
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              fromNodeId: 'some-trigger-uuid'
              toNodeId: 'some-debug-uuid'
              message: 12455663

      describe 'when the trigger node is wired to two debug nodes', ->
        beforeEach ->
          @datastore.get.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid', 'some-other-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []
            'some-other-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []

        describe 'when given an envelope', ->
          beforeEach ->
            @sut.onEnvelope
              flowId: 'some-flow-uuid'
              instanceId: 'some-instance-uuid'
              deploymentId: 'raging-rhino'
              fromNodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call datastore.get', ->
            expect(@datastore.get).to.have.been.called

          it 'should call onEnvelope in the debugNode twice', ->
            expect(@debugNodeOnEnvelope).to.have.been.calledTwice

          it 'should call onEnvelope in the debugNode', ->
            expect(@debugNodeOnEnvelope).to.have.been.calledWith
              flowId: 'some-flow-uuid'
              instanceId: 'some-instance-uuid'
              fromNodeId: 'some-trigger-uuid'
              toNodeId: 'some-debug-uuid'
              message: 12455663

            expect(@debugNodeOnEnvelope).to.have.been.calledWith
              flowId: 'some-flow-uuid'
              instanceId: 'some-instance-uuid'
              toNodeId: 'some-other-debug-uuid'
              fromNodeId: 'some-trigger-uuid'
              message: 12455663

      describe 'when the trigger node is wired to two debug nodes and another mystery node', ->
        beforeEach ->
          @datastore.get.yields null,
            'some-interval-uuid':
              type: 'nanocyte-node-interval'
              linkedTo: ['some-debug-uuid']
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid', 'some-other-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []
            'some-other-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []

        describe 'when given an envelope', ->
          beforeEach ->
            @sut.onEnvelope fromNodeId: 'some-trigger-uuid', message: 12455663

          it 'should call datastore.get', ->
            expect(@datastore.get).to.have.been.called

          it 'should call onEnvelope in the debugNode twice', ->
            expect(@debugNodeOnEnvelope).to.have.been.calledTwice
