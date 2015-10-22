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
      constructor: ->
        @stream = new TestStream
        @stream.onWrite = (envelope, callback) =>
          DebugNode.messages.push envelope
          callback null, envelope
          callback null, null

      message: (envelope) =>
        DebugNode.messageCount++
        @stream.write envelope
        @stream

      @messageCount: 0
      @messages: []


    @DebugNode = DebugNode

    class EngineDebugNode
      constructor: ->
        @stream = new TestStream
        @stream.onWrite = (envelope, callback) =>
          EngineDebugNode.messages.push envelope
          callback null, envelope
          callback null, null

      message: (envelope) =>
        EngineDebugNode.messageCount++
        @stream.write envelope
        @stream

      @messageCount: 0
      @messages: []

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
        beforeEach (done)->
          @datastore.hget.yields null,
            'some-trigger-uuid':
              type: 'nanocyte-node-trigger'
              linkedTo: ['some-debug-uuid']
            'some-debug-uuid':
              type: 'nanocyte-node-debug'
              transactionGroupId: 'some-group-id'

          @sut.initialize done

        describe 'when given an envelope without a transaction', ->
          beforeEach ->
            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @sut.on 'finish', done
              @lockManager.lock.yield null, 'a-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id'

            it 'should call onEnvelope in the debugNode with the envelope', ->
              expect(@DebugNode.messages).to.contain
                metadata:
                  flowId: 'some-flow-uuid'
                  instanceId: 'instance-uuid'
                  nodeId: 'some-debug-uuid'
                  transactionId: 'a-transaction-id'

                message: 12455663

          describe 'when the lockManager yields an error', ->
            beforeEach ->
              @lockManager.lock.yield new Error "Locks are for chumps"

            it 'should not continue routing the message', ->
              expect(@DebugNode.messages.length).to.equal 0

        describe 'when given an envelope with a transaction', ->
          beforeEach ->
            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
                transactionId: 'some-previous-transaction-id'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @sut.on 'finish', done
              @lockManager.lock.yield null, 'some-previous-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id', 'some-previous-transaction-id'

            it 'should call message in the debugNode with the envelope', ->
              expect(@DebugNode.messages).to.contain
                metadata:
                  flowId: 'some-flow-uuid'
                  instanceId: 'instance-uuid'
                  nodeId: 'some-debug-uuid'
                  transactionId: 'some-previous-transaction-id'
                message: 12455663

          describe 'when the messaged component is done', ->
            beforeEach (done) ->
              @sut.on 'finish', done
              @lockManager.lock.yield null, 'some-previous-transaction-id'


            it 'should call lockmanager.unlock with the transactionId and transactionGroupId', ->
              expect(@lockManager.unlock).to.have.been.calledWith 'some-group-id', 'some-previous-transaction-id'


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
            @sut.on 'finish', done

            @sut.message
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-trigger-uuid'
              message: 12455663

            @lockManager.lock.yield null, 'some-previous-transaction-id'

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.messageCount).to.equal 2

          it 'should call message in the debugNode', ->
            expect(@DebugNode.messages).to.contain
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                nodeId: 'some-debug-uuid'
              message: 12455663

            expect(@DebugNode.messages).to.contain
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
            @sut.on 'finish', done

            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
              message: 12455663

            @lockManager.lock.yield null, 'some-previous-transaction-id'

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.messageCount).to.equal 2

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
              type: 'engine-debug'
              linkedTo: []

          @sut.initialize => done()

        describe 'when given an envelope', ->
          beforeEach (done) ->
            @sut.on 'finish', done
            @lockManager.lock.yields null, 'some-previous-transaction-id'

            @sut.message
              metadata:
                nodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode', ->
            expect(@DebugNode.messageCount).to.equal 1

          it 'should call message in the engineDebugNode', ->
            expect(@EngineDebugNode.messageCount).to.equal 1

  describe 'initialize', ->
    describe 'when called and hget returns no data', ->
      beforeEach (done) ->
        @sut.initialize (@error) => done()
        @datastore.hget.yield null, null

      it 'should call datastore.hget', ->
        expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'some-instance-uuid/router/config'

      it 'should call the callback with an error', ->
        expect(@error).to.exist

    describe 'when called and hget returns an error', ->
      beforeEach (done) ->
        @sut.initialize (@error) => done()
        @datastore.hget.yield new Error 'oh no', null

      it 'should call datastore.hget', ->
        expect(@datastore.hget).to.have.been.calledWith 'some-flow-uuid', 'some-instance-uuid/router/config'

      it 'should call the callback with an error', ->
        expect(@error).to.exist
