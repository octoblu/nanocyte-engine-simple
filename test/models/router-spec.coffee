Router = require '../../src/models/router'
_ = require 'lodash'

describe 'Router', ->
  beforeEach ->
    @datastore = hget: sinon.stub()
    @lockManager =
      lock: sinon.stub()
      unlock: sinon.stub()

    class DebugNode
      onEnvelope: sinon.spy()

    @DebugNode = DebugNode

    @assembleNodes = assembleNodes = sinon.stub().returns 'nanocyte-node-debug': DebugNode

    class NodeAssembler
      assembleNodes: assembleNodes

    @sut = new Router {datastore: @datastore, NodeAssembler: NodeAssembler, lockManager: @lockManager}

  describe 'onEnvelope', ->
    describe 'when the nodeAssembler returns some nodes', ->
      describe 'when the datastore yields nothing for the flowId', ->
        beforeEach ->
          @datastore.hget.yields null, null

        describe 'when given an envelope', ->
          beforeEach ->
            try
              @sut.onEnvelope
                fromNodeId: 'some-trigger-uuid'
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                message: 12455663

            catch error
              @error = error

          it 'should not be a little sissy about it', ->
            expect(@error).to.not.exist

          it 'should call assembleNodes on the nodeAssembler', ->
            expect(@assembleNodes).to.have.been.called

      describe 'when the trigger node is wired to a nonexistent node', ->
        beforeEach ->
          @datastore.hget.yields null,
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
          @datastore.hget.yields null, {}

        it 'should not be a little sissy about it', ->
          theCall = => @sut.onEnvelope
            fromNodeId: 'some-trigger-uuid'
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the datastore yields a nodetype that doesnt exist', ->
        beforeEach ->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-mystery-uuid']
            'some-mystery-uuid':
              type: 'nanocyte-component-its-a-mystery'
              linkedTo: []

        it 'should not be a little sissy about it', ->
          theCall = => @sut.onEnvelope
            fromNodeId: 'some-trigger-uuid'
            flowId: 'some-flow-uuid'
            instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the trigger node is wired to a debug node', ->
        beforeEach ->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: []

        describe 'when given an envelope without a transaction', ->
          beforeEach ->
            @sut.onEnvelope
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              transactionGroupId: 'some-group-id'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @DebugNode.onEnvelope = sinon.spy => done()
              @lockManager.lock.yield null, 'a-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id'

            it 'should call datastore.hget', ->
              expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'instance-uuid/router/config'

            it 'should call onEnvelope in the debugNode with the envelope', ->
              expect(@DebugNode.onEnvelope).to.have.been.calledWith
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                fromNodeId: 'some-trigger-uuid'
                toNodeId: 'some-debug-uuid'
                transactionGroupId: 'some-group-id'
                transactionId: 'a-transaction-id'
                message: 12455663

        describe 'when given an envelope with a transaction', ->
          beforeEach ->
            @sut.onEnvelope
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              transactionGroupId: 'some-other-group-id'
              transactionId: 'some-previous-transaction-id'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @DebugNode.onEnvelope = sinon.spy => done()
              @lockManager.lock.yield null, 'some-previous-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-other-group-id', 'some-previous-transaction-id'

            it 'should call datastore.hget', ->
              expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'instance-uuid/router/config'

            it 'should call onEnvelope in the debugNode with the envelope', ->
              expect(@DebugNode.onEnvelope).to.have.been.calledWith
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                fromNodeId: 'some-trigger-uuid'
                toNodeId: 'some-debug-uuid'
                transactionGroupId: 'some-other-group-id'
                transactionId: 'some-previous-transaction-id'
                message: 12455663

          describe 'when the messaged component is done', ->
            beforeEach (done) ->
              @DebugNode.onEnvelope = (envelope, next, end) =>
                end null, transactionGroupId: 'a-even-more-different-group', transactionId: 'some-other-transaction-id'
                done()
              @lockManager.lock.yield null, 'some-previous-transaction-id'

            it 'should call lockmanager.unlock with the transactionId and transactionGroupId', ->
              expect(@lockManager.unlock).to.have.been.calledWith 'a-even-more-different-group', 'some-other-transaction-id'


      describe 'when the trigger node is wired to two debug nodes', ->
        beforeEach ->
          @datastore.hget.yields null,
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
          beforeEach (done) ->
            doneTwice = _.after 2, done
            @DebugNode.onEnvelope = sinon.spy => doneTwice()

            @lockManager.lock.yields null, 'some-previous-transaction-id'

            @sut.onEnvelope
              flowId: 'some-flow-uuid'
              transactionGroupId: 'whatever'
              instanceId: 'some-instance-uuid'
              deploymentId: 'raging-rhino'
              fromNodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call datastore.hget', ->
            expect(@datastore.hget).to.have.been.called

          it 'should call onEnvelope in the debugNode twice', ->
            expect(@DebugNode.onEnvelope).to.have.been.calledTwice

          it 'should call onEnvelope in the debugNode', ->
            expect(@DebugNode.onEnvelope).to.have.been.calledWith
              flowId: 'some-flow-uuid'
              transactionId: 'some-previous-transaction-id'
              transactionGroupId: 'whatever'
              instanceId: 'some-instance-uuid'
              fromNodeId: 'some-trigger-uuid'
              toNodeId: 'some-debug-uuid'
              message: 12455663

            expect(@DebugNode.onEnvelope).to.have.been.calledWith
              transactionId: 'some-previous-transaction-id'
              transactionGroupId: 'whatever'
              flowId: 'some-flow-uuid'
              instanceId: 'some-instance-uuid'
              toNodeId: 'some-other-debug-uuid'
              fromNodeId: 'some-trigger-uuid'
              message: 12455663

      describe 'when the trigger node is wired to two debug nodes and another mystery node', ->
        beforeEach ->
          @datastore.hget.yields null,
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
          beforeEach (done) ->
            doneTwice = _.after 2, done
            @DebugNode.onEnvelope = sinon.spy =>
              doneTwice()

            @lockManager.lock.yields null, 'whatever'

            @sut.onEnvelope fromNodeId: 'some-trigger-uuid', message: 12455663

          it 'should call datastore.hget', ->
            expect(@datastore.hget).to.have.been.called

          it 'should call onEnvelope in the debugNode twice', ->
            expect(@DebugNode.onEnvelope).to.have.been.calledTwice
