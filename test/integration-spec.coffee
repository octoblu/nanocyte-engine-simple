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
            params: {
              foo: 'bar'
            }

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
