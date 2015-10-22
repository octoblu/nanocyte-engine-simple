Router = require '../../src/models/router'
_ = require 'lodash'

TestStream = require '../helpers/test-stream'

describe 'Router', ->
  beforeEach ->
    @datastore = hget: sinon.stub()

    @lockManager =
      lock: sinon.stub()
      unlock: sinon.stub()

    @debugNodeStream = debugNodeStream = new TestStream

    class DebugNode
      constructor: ->        
        @message = DebugNode.debugNodeMessage

      @debugNodeMessage: sinon.spy (envelope) =>
        debugNodeStream.write envelope
        debugNodeStream

    @DebugNode = DebugNode

    class EngineDebugNode
      message: sinon.stub().returns new TestStream()

    @EngineDebugNode = EngineDebugNode

    @assembleNodes = assembleNodes = sinon.stub().returns
      'nanocyte-node-debug': DebugNode
      'engine-debug' : EngineDebugNode

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
            @debugNodeStream.onWrite (newEnvelope, callback) =>
              console.log "onWrite", newEnvelope
              done()

            @sut.message
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it.only 'should call message in the debugNode twice', ->
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
            # @sut.on 'finish', done

            @debugNodeStream.onWrite = (newEnvelope, callback) =>
              console.log "I GOT AN ENVELOPE", newEnvelope
              callback null, newEnvelope

            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call datastore.hget', ->
            expect(@datastore.hget).to.have.been.called

          it.only 'should call message in the debugNode twice', ->
            expect(@DebugNode.message).to.have.been.calledTwice

      describe 'when the trigger node is wired to a debug node thats wired to engine-debug', ->
        beforeEach (done) ->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              linkedTo: ['engine-debug']
            'engine-debug':
              type: 'nanocyte-node-debug'
              linkedTo: []

          @sut.initialize => done()

        describe 'when given an envelope', ->
          beforeEach (done) ->
            @sut.on 'finish', done
            @EngineDebugNode.message = sinon.spy =>
              doneTwice()

            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode', ->
            expect(@DebugNode.message).to.have.been.called

          it 'should call message in the engineDebugNode', ->
            expect(@EngineDebugNode.message).to.have.been.called
