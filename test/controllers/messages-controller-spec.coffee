MessagesController = require '../../src/controllers/messages-controller'

describe '/messages', ->
  beforeEach ->
    @inputHandler =
      onMessage: sinon.spy()

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

    @sut = new MessagesController inputHandler: @inputHandler

  describe 'when /messages receives a message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-flow-uuid'
        body:
          foo: 'bar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputHandler.onMessage).to.have.been.calledWith foo: 'bar', flowId: 'some-flow-uuid'

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

  describe 'when /messages receives a different message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-other-flow-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputHandler.onMessage).to.have.been.calledWith shoe: 'spar', flowId: 'some-other-flow-uuid'
