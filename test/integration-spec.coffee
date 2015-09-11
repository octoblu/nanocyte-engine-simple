describe 'sending a message to a trigger node', ->
  beforeEach ->
    @triggerNode = require '../src/models/unwrapped-trigger-node-to-be-replaced'
    sinon.stub @triggerNode, 'onMessage'

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

    MessagesController = require '../src/controllers/messages-controller'
    @sut = new MessagesController

  afterEach ->
    @triggerNode.onMessage.restore()

  describe 'when /messages receives a message', ->
    beforeEach ->
      request =
        body:
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'some-trigger-uuid'
            params:
              foo: 'bar'

      @sut.create request, @response

    it 'should call onMessage on the triggerNode', ->
      expect(@triggerNode.onMessage).to.have.been.calledWith params: {foo: 'bar'}

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

  describe 'when /messages receives a different message', ->
    beforeEach ->
      request =
        body:
          topic: 'button'
          devices: ['some-flow-uuid']
          payload:
            from: 'some-trigger-uuid'
            parmesian: {
              something: 'completely-different'
            }

      @sut.create request, @response

    it 'should call onMessage on the triggerNode', ->
      expect(@triggerNode.onMessage).to.have.been.calledWith parmesian: {something: 'completely-different'}

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

describe 'and now a word from trigger, to the debug node', ->
  beforeEach ->
    @inputHandler = require '../src/handlers/input-handler'
    @triggerNode = require '../src/models/unwrapped-trigger-node-to-be-replaced'
    @debugNode = require '../src/models/unwrapped-debug-node-to-be-replaced'
    sinon.stub(@triggerNode, 'onMessage').yields null, from: 'some-trigger-uuid', message: 123456
    sinon.stub @debugNode, 'onMessage'

    @inputHandler.onMessage
      topic: 'button'
      devices: ['some-flow-uuid']
      payload:
        from: 'some-trigger-uuid'
        parmesian:
          something: 'completely-different'

  afterEach ->
    @triggerNode.onMessage.restore()
    @debugNode.onMessage.restore()

  it 'should call onMessage on the debug node', ->
    expect(@debugNode.onMessage).to.have.been.called
