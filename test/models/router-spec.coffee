Router = require '../../src/models/router'
_ = require 'lodash'

TestStream = require '../helpers/test-stream'

describe 'Router', ->
  beforeEach ->
    @datastore = hget: sinon.stub()

    @lockManager =
      lock: sinon.stub()
      unlock: sinon.stub()

    class DebugNode
      message: sinon.stub().returns new TestStream()

    @DebugNode = DebugNode

    @assembleNodes = assembleNodes = sinon.stub().returns 'nanocyte-node-debug': DebugNode

    class NodeAssembler
      assembleNodes: assembleNodes

    @sut = new Router 'some-flow-uuid', 'some-instance-uuid', {datastore: @datastore, NodeAssembler: NodeAssembler, lockManager: @lockManager}

  describe 'message', ->
    describe 'when the nodeAssembler returns some nodes', ->
      describe 'when the datastore yields nothing for the flowId', ->
        beforeEach (done) ->
          @datastore.hget.yields null, null
          @sut.initialize (@error) => done()


        it 'should call the callback with an error', ->
          expect(@error).to.exist

        describe 'when message is called anyway', ->
          it 'should not be a little sissy about it', ->
            theCall = => @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
              message: 12455663
            expect(theCall).not.to.throw()

        describe 'when message is called without metadata', ->
          it 'should not be a little sissy about it', ->
            theCall = => @sut.message
              message: 12455663
            expect(theCall).not.to.throw()

        describe 'when message is called without an envelope', ->
          it 'should not be a little sissy about it', ->
            theCall = => @sut.message()
            expect(theCall).not.to.throw()

      describe 'when the trigger node is wired to a nonexistent node', ->
        beforeEach (done) ->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']
              transactionGroupId: 'transaction-group-id'

          @sut.initialize => done()

        it 'should not be a little sissy about it', ->
          theCall = => @sut.message
            metadata:
              nodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the trigger node doesnt exist', ->
        beforeEach (done) ->
          @datastore.hget.yields null, {}
          @sut.initialize => done()

        it 'should not be a little sissy about it', ->
          theCall = => @sut.message
            metadata:
              nodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
            message: 12455663
          expect(theCall).not.to.throw()

      describe 'when the datastore yields a nodetype that doesnt exist', ->
        beforeEach (done)->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-mystery-uuid']
            'some-mystery-uuid':
              type: 'nanocyte-component-its-a-mystery'
              linkedTo: []

          @sut.initialize => done()

        it 'should not be a little sissy about it', ->
          theCall = => @sut.message
            metadata:
              nodeId: 'some-trigger-uuid'
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
              transactionGroupId: 'some-group-id'
              linkedTo: []

        xdescribe 'when given an envelope without a transaction', ->
          beforeEach ->
            @sut.message
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @DebugNode.message = sinon.spy => done()
              @lockManager.lock.yield null, 'a-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id'

            it 'should call datastore.hget', ->
              expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'instance-uuid/router/config'

            it 'should call message in the debugNode with the envelope', ->
              expect(@DebugNode.message).to.have.been.calledWith
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                fromNodeId: 'some-trigger-uuid'
                toNodeId: 'some-debug-uuid'
                transactionId: 'a-transaction-id'
                message: 12455663

          describe 'when the lockManager yields an error', ->
            beforeEach ->
              @DebugNode.message = sinon.spy()
              @lockManager.lock.yield new Error "Locks are for chumps"

            it 'should not continue routing the message', ->
              expect(@DebugNode.message).to.not.have.been.called

        xdescribe 'when given an envelope with a transaction', ->
          beforeEach ->
            @sut.message
              fromNodeId: 'some-trigger-uuid'
              flowId: 'some-flow-uuid'
              instanceId: 'instance-uuid'
              transactionId: 'some-previous-transaction-id'
              message: 12455663

          xdescribe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @DebugNode.message = sinon.spy => done()
              @lockManager.lock.yield null, 'some-previous-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id', 'some-previous-transaction-id'

            it 'should call datastore.hget', ->
              expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'instance-uuid/router/config'

            it 'should call message in the debugNode with the envelope', ->
              expect(@DebugNode.message).to.have.been.calledWith
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                fromNodeId: 'some-trigger-uuid'
                toNodeId: 'some-debug-uuid'
                transactionId: 'some-previous-transaction-id'
                message: 12455663

          describe 'when the messaged component is done', ->
            beforeEach (done) ->
              @DebugNode.message = (envelope, next, end) =>
                end null, transactionId: 'some-other-transaction-id'
                done()
              @lockManager.lock.yield null, 'some-previous-transaction-id'

            it 'should call lockmanager.unlock with the transactionId and transactionGroupId', ->
              expect(@lockManager.unlock).to.have.been.calledWith 'some-group-id', 'some-other-transaction-id'


      describe 'when the trigger node is wired to two debug nodes', ->
        beforeEach (done) ->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid', 'some-other-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              transactionGroupId: 'some-group-id'
              linkedTo: []
            'some-other-debug-uuid':
              type: 'nanocyte-node-debug'
              transactionGroupId: 'some-group-id'
              linkedTo: []

          @sut.initialize => done()

        describe 'when given an envelope', ->
          beforeEach (done) ->
            doneTwice = _.after 2, done
            @DebugNode.message = sinon.spy => doneTwice()

            @lockManager.lock.yields null, 'some-previous-transaction-id'

            @sut.message
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.message).to.have.been.calledTwice

          it 'should call message in the debugNode', ->
            expect(@DebugNode.message).to.have.been.calledWith
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-debug-uuid'
              message: 12455663

            expect(@DebugNode.message).to.have.been.calledWith
              metadata:
                transactionId: 'some-previous-transaction-id'
                flowId: 'some-flow-uuid'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-other-debug-uuid'
              message: 12455663

      describe 'when the trigger node is wired to two debug nodes and another mystery node', ->
        beforeEach (done) ->
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

          @sut.initialize => done()

        describe 'when given an envelope', ->
          beforeEach (done) ->
            doneTwice = _.after 2, done
            @DebugNode.message = sinon.spy =>
              doneTwice()

            @lockManager.lock.yields null, 'whatever'

            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call datastore.hget', ->
            expect(@datastore.hget).to.have.been.called

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.message).to.have.been.calledTwice
