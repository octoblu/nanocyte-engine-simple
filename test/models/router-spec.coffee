Router = require '../../src/models/router'

describe 'Router', ->
  beforeEach ->
    @datastore = get: sinon.stub()
    @sut = new Router datastore: @datastore

  describe 'onMessage', ->
    describe 'when the trigger node is wired to a debug node', ->
      beforeEach ->
        @datastore.get.yields null,
          links: [
            from: 'some-trigger-uuid'
            to: 'some-debug-uuid'
          ]

      describe 'when given an envelope', ->
        beforeEach ->
          @debugNode = require '../../src/models/unwrapped-debug-node-to-be-replaced'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage nodeId: 'some-trigger-uuid', flowId: 'some-flow-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.calledWith 'some-flow-uuid'

        it 'should call onMessage in the debugNode one time', ->
          expect(@debugNode.onMessage).to.have.been.calledOnce

        it 'should call onMessage in the debugNode with envelope.message', ->
          expect(@debugNode.onMessage).to.have.been.calledWith 12455663

    describe 'when the trigger node is wired to two debug nodes', ->
      beforeEach ->
        @datastore.get.yields null,
          links: [
            from: 'some-trigger-uuid'
            to: 'some-debug-uuid'
          ,
            from: 'some-trigger-uuid'
            to: 'some-other-debug-uuid'
          ]

      describe 'when given an envelope', ->
        beforeEach ->
          @debugNode = require '../../src/models/wrapped-debug-node'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage nodeId: 'some-trigger-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.called

        it 'should call onMessage in the debugNode twice', ->
          expect(@debugNode.onMessage).to.have.been.calledTwice

        it 'should call onMessage in the debugNode', ->
          expect(@debugNode.onMessage).to.have.been.calledWith nodeId: 'some-debug-uuid', flowId: 'some-flow-uuid', message: 12455663
          expect(@debugNode.onMessage).to.have.been.calledWith nodeId: 'some-other-debug-uuid', flowId: 'some-flow-uuid', message: 12455663

    describe 'when the trigger node is wired to two debug nodes and another mystery node', ->
      beforeEach ->
        @datastore.get.yields null,
          links: [
            from: 'some-interval-uuid'
            to: 'some-debug-uuid'
          ,
            from: 'some-trigger-uuid'
            to: 'some-debug-uuid'
          ,
            from: 'some-trigger-uuid'
            to: 'some-other-debug-uuid'
          ]

      describe 'when given an envelope', ->
        beforeEach ->
          @debugNode = require '../../src/models/unwrapped-debug-node-to-be-replaced'
          sinon.stub @debugNode, 'onMessage'
          @sut.onMessage nodeId: 'some-trigger-uuid', message: 12455663

        afterEach ->
          @debugNode.onMessage.restore()

        it 'should call datastore.get', ->
          expect(@datastore.get).to.have.been.called

        it 'should call onMessage in the debugNode twice', ->
          expect(@debugNode.onMessage).to.have.been.calledTwice
