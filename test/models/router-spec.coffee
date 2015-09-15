Router = require '../../src/models/router'

describe 'Router', ->
  beforeEach ->
    @datastore = get: sinon.stub()
    @sut = new Router datastore: @datastore

  describe 'onMessage', ->
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
          @debugNode = require '../../src/models/wrapped-debug-node'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage toNodeId: 'some-trigger-uuid', flowId: 'some-flow-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.calledWith 'some-flow-uuid/router/config'

        it 'should call onMessage in the debugNode one time', ->
          expect(@debugNode.onMessage).to.have.been.calledOnce

        it 'should call onMessage in the debugNode with envelope.message', ->
          expect(@debugNode.onMessage).to.have.been.calledWith
            fromNodeId: 'some-trigger-uuid'
            toNodeId: 'some-debug-uuid'
            flowId: 'some-flow-uuid'
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
          @debugNode = require '../../src/models/wrapped-debug-node'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage flowId: 'some-flow-uuid', toNodeId: 'some-trigger-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.called

        it 'should call onMessage in the debugNode twice', ->
          expect(@debugNode.onMessage).to.have.been.calledTwice

        it 'should call onMessage in the debugNode', ->
          expect(@debugNode.onMessage).to.have.been.calledWith
            fromNodeId: 'some-trigger-uuid'
            toNodeId: 'some-debug-uuid'
            flowId: 'some-flow-uuid'
            message: 12455663

          expect(@debugNode.onMessage).to.have.been.calledWith
            toNodeId: 'some-other-debug-uuid'
            fromNodeId: 'some-trigger-uuid'
            flowId: 'some-flow-uuid'
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
          @debugNode = require '../../src/models/wrapped-debug-node'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage toNodeId: 'some-trigger-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.called

        it 'should call onMessage in the debugNode twice', ->
          expect(@debugNode.onMessage).to.have.been.calledTwice
