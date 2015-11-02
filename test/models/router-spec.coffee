Router = require '../../src/models/router'
_ = require 'lodash'

TestStream = require '../helpers/test-stream'

describe 'Router', ->
  beforeEach ->
    @datastore = hget: sinon.stub()

    @lockManager =
      lock: sinon.stub()
      unlock: sinon.stub()

    class EngineNode
      constructor: (@messages=[])->
        @stream = new TestStream
        @stream.onWrite = (envelope, callback) =>
          @messages.push envelope

          envelope = _.cloneDeep envelope
          envelope.metadata.fromNodeId = envelope.metadata.toNodeId
          delete envelope.metadata.toNodeId

          callback null, envelope
          callback null, null

      message: (envelope) =>
        @stream.write envelope
        @stream

    class DebugNode extends EngineNode
      constructor: ->
        super DebugNode.messages
      @messages: []

    @DebugNode = DebugNode

    class EngineDebugNode extends EngineNode
      constructor: ->
        super EngineDebugNode.messages
      @messages: []

    @EngineDebugNode = EngineDebugNode

    class EnginePulseNode extends EngineNode
      constructor: ->
        super EnginePulseNode.messages
      @messages: []

    @EnginePulseNode = EnginePulseNode

    class EngineOutputNode extends EngineNode
      constructor: ->
        super EngineOutputNode.messages
      @messages: []

    @EngineOutputNode = EngineOutputNode

    #nanocyte nodes need to close the stream
    class PulseNode extends EngineNode
      constructor: ->
        super PulseNode.messages
      @messages: []

    @PulseNode = PulseNode

    @assembleNodes = assembleNodes = sinon.stub().returns
      'nanocyte-node-debug': DebugNode
      'engine-debug' : EngineDebugNode
      'engine-output': EngineOutputNode
      'engine-pulse' : EnginePulseNode
      'pulse': PulseNode

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
                fromNodeId: 'some-trigger-uuid'
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
              fromNodeId: 'some-trigger-uuid'
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
              fromNodeId: 'some-trigger-uuid'
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
              fromNodeId: 'some-trigger-uuid'
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
                fromNodeId: 'some-trigger-uuid'
                flowId: 'some-flow-uuid'
                instanceId: 'instance-uuid'
              message: 12455663

          describe 'when the lockManager yields a transaction-id', ->
            beforeEach (done) ->
              @sut.on 'finish', done
              @lockManager.lock.yield null, 'a-transaction-id'

            it 'should call lockManager.lock with the transactionGroupId', ->
              expect(@lockManager.lock).to.have.been.calledWith 'some-group-id'

            it 'should call message on the debugNode with the envelope', ->
              expect(@DebugNode.messages[0]).to.deep.equal
                metadata:
                  flowId: 'some-flow-uuid'
                  instanceId: 'instance-uuid'
                  toNodeId: 'some-debug-uuid'
                  fromNodeId: 'some-trigger-uuid'
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
                fromNodeId: 'some-trigger-uuid'
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
              expect(@DebugNode.messages[0]).to.deep.equal
                metadata:
                  flowId: 'some-flow-uuid'
                  instanceId: 'instance-uuid'
                  toNodeId: 'some-debug-uuid'
                  fromNodeId: 'some-trigger-uuid'
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
            @lockManager.lock.yields null, 'some-previous-transaction-id'

            @sut.message
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                fromNodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.messages.length).to.equal 2

          it 'should call message in the debugNode', ->
            expect(@DebugNode.messages).to.contain
              metadata:
                flowId: 'some-flow-uuid'
                transactionId: 'some-previous-transaction-id'
                instanceId: 'some-instance-uuid'
                toNodeId: 'some-debug-uuid'
                fromNodeId: 'some-trigger-uuid'
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
            @lockManager.lock.yields null, 'some-previous-transaction-id'

            @sut.message
              metadata:
                fromNodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode twice', ->
            expect(@DebugNode.messages.length).to.equal 2

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
                fromNodeId: 'some-trigger-uuid'
              message: 12455663

          it 'should call message in the debugNode', ->
            expect(@DebugNode.messages.length).to.equal 1

          it 'should call message in the engineDebugNode', ->
            expect(@EngineDebugNode.messages.length).to.equal 1

      describe 'when an engine-debug emits a message', ->
        beforeEach (done) ->
          @lockManager.lock.yields null, 'who-cares'
          @datastore.hget.yields null,
            'engine-debug':
              type: 'engine-debug'
              linkedTo: []
            'engine-output':
              type: 'engine-output'
              linkedTo: []

          @sut.initialize => done()

        beforeEach (done) ->
          @sut.on 'finish', done
          @debugEnvelope =
            metadata:
              fromNodeId: 'engine-debug'
            message:
              debugging: "It's not just for chumps anymore"

          @sut.message @debugEnvelope

        it 'should route the message to engine-output', ->
          expect(@EngineOutputNode.messages.length).to.equal 1
          expect(@EngineOutputNode.messages[0].message).to.deep.equal @debugEnvelope.message

    describe 'when an engine-pulse emits a message', ->
      beforeEach (done) ->
        @lockManager.lock.yields null, 'who-cares'
        @datastore.hget.yields null,
          'engine-pulse':
            type: 'engine-pulse'
            linkedTo: []
          'engine-output':
            type: 'engine-output'
            linkedTo: []

        @sut.initialize => done()

      beforeEach (done) ->
        @sut.on 'finish', done
        @pulseMessage =
          metadata:
            fromNodeId: 'engine-pulse'
          message:
            'star-type': 'pulsar'
        @sut.message @pulseMessage

      it 'should route the message to engine-output', ->
        expect(@EngineOutputNode.messages.length).to.equal 1
        expect(@EngineOutputNode.messages[0].message).to.deep.equal @pulseMessage.message

    describe 'when an engine-pulse emits a message and engine-output has a different id for some reason', ->
      beforeEach (done) ->
        @lockManager.lock.yields null, 'who-cares'
        @datastore.hget.yields null,
          'engine-pulse':
            type: 'engine-pulse'
            linkedTo: []
          'engine-smoutput':
            type: 'engine-output'
            linkedTo: []

        @sut.initialize => done()

      beforeEach (done) ->
        @sut.on 'finish', done
        @pulseMessage =
          metadata:
            fromNodeId: 'engine-pulse'
          message:
            'star-type': 'pulsar'
        @sut.message @pulseMessage

      it 'should still route the message to the engine-output', ->
        expect(@EngineOutputNode.messages.length).to.equal 1
        expect(@EngineOutputNode.messages[0].message).to.deep.equal @pulseMessage.message

    describe 'when an engine-pulse emits a message there is no engine-output', ->
      beforeEach (done) ->
        @lockManager.lock.yields null, 'who-cares'
        @datastore.hget.yields null,
          'pulse':
            type: 'pulse'
            linkedTo: ['engine-pulse']
          'engine-pulse':
            type: 'engine-pulse'
            linkedTo: []
          'engine-output':
            type: 'engine-kroutput'
            linkedTo: []

        @sut.initialize => done()

      beforeEach (done) ->
        @sut.on 'finish', done
        @pulseMessage =
          metadata:
            fromNodeId: 'pulse'
          message:
            'star-type': 'pulsar'
        @sut.message @pulseMessage

      it 'should not try to route the message to the engine-output', ->
        expect(@EngineOutputNode.messages.length).to.equal 0

    describe 'when an engine-debug emits a message and engine-debug is already connected to engine-output', ->
      beforeEach (done) ->
        @lockManager.lock.yields null, 'who-cares'
        @datastore.hget.yields null,
          'engine-debug':
            type: 'engine-debug'
            linkedTo: ['engine-output']
          'engine-output':
            type: 'engine-output'
            linkedTo: []

        @sut.initialize => done()

      beforeEach (done) ->
        @sut.on 'finish', done
        @pulseMessage =
          metadata:
            fromNodeId: 'engine-debug'
          message:
            'debug-type': 'dragonfly'
        @sut.message @pulseMessage

      it 'should only route one message to engine-output', ->
        expect(@EngineOutputNode.messages.length).to.equal 1
        expect(@EngineOutputNode.messages[0].message).to.deep.equal @pulseMessage.message

    describe 'when an engine-pulse emits a message and engine-pulse is already connected to engine-output', ->
      beforeEach (done) ->
        @lockManager.lock.yields null, 'who-cares'
        @datastore.hget.yields null,
          'engine-pulse':
            type: 'engine-pulse'
            linkedTo: ['engine-output']
          'engine-output':
            type: 'engine-output'
            linkedTo: []

        @sut.initialize => done()

      beforeEach (done) ->
        @sut.on 'finish', done
        @pulseMessage =
          metadata:
            fromNodeId: 'engine-pulse'
          message:
            'star-type': 'pulsar'
        @sut.message @pulseMessage

      it 'should only route one message to engine-output', ->
        expect(@EngineOutputNode.messages.length).to.equal 1
        expect(@EngineOutputNode.messages[0].message).to.deep.equal @pulseMessage.message

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
