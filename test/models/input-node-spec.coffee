InputNode = require '../../src/models/input-node'

describe 'InputNode', ->
  beforeEach ->
    @triggerNode = require '../../src/models/unwrapped-trigger-node-to-be-replaced'
    sinon.stub @triggerNode, 'onMessage'

    @sut = new InputNode

  afterEach ->
    @triggerNode.onMessage.restore()

  it 'should be', ->
    expect(@sut).to.exist

  it 'should create a trigger node', ->
    expect(@sut.triggerNode).to.exist

  describe 'onMessage', ->
    describe 'with a meshblu message', ->
      beforeEach ->

        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'some-trigger-uuid'
            params:
              foo: 'bar'

      it 'should send a converted message to triggerNode', ->
        expect(@triggerNode.onMessage).to.have.been.calledWith params: {foo: 'bar'}

    describe 'with a different meshblu message', ->
      beforeEach ->

        @sut.onMessage
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'some-trigger-uuid'
            pep: 'step'

      it 'should send a converted message to triggerNode', ->
        expect(@triggerNode.onMessage).to.have.been.calledWith pep: 'step'
