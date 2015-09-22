MessagesController = require '../../src/controllers/messages-controller'

describe '/messages', ->
  beforeEach ->
    @inputNode =
      onMessage: sinon.spy()

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

    @sut = new MessagesController inputNode: @inputNode

  describe 'when /messages receives a message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'
        body:
          foo: 'bar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputNode.onMessage).to.have.been.calledWith foo: 'bar', flowId: 'some-flow-uuid', instanceId: 'some-instance-uuid'

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

  describe 'when /messages receives a different message', ->
    beforeEach ->
      request =
        params:
          flowId:     'some-other-flow-uuid'
          instanceId: 'some-instance-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputNode.onMessage).to.have.been.calledWith shoe: 'spar', flowId: 'some-other-flow-uuid', instanceId: 'some-instance-uuid'
