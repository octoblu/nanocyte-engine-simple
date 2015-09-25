MessagesController = require '../../src/controllers/messages-controller'

describe '/messages', ->
  beforeEach ->
    @inputNode =
      onMessage: sinon.spy()

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

    @sut = new MessagesController inputNode: @inputNode

  describe 'when /messages receives an authorized message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'
        meshbluAuth:
          uuid: 'some-flow-uuid'
        body:
          foo: 'bar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputNode.onMessage).to.have.been.calledWith
        foo: 'bar'
        flowId: 'some-flow-uuid'
        instanceId: 'some-instance-uuid'

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

  describe 'when /messages receives a different authorized message', ->
    beforeEach ->
      request =
        params:
          flowId:     'some-other-flow-uuid'
          instanceId: 'some-instance-uuid'
        meshbluAuth:
          uuid: 'some-other-flow-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should call onMessage on the appropriate node', ->
      expect(@inputNode.onMessage).to.have.been.calledWith
        shoe: 'spar'
        flowId: 'some-other-flow-uuid'
        instanceId: 'some-instance-uuid'

  describe 'when /messages receives a different authorized message from the wrong uuid', ->
    beforeEach ->
      request =
        params:
          flowId:     'some-other-flow-uuid'
          instanceId: 'some-instance-uuid'
        meshbluAuth:
          uuid: 'wrong-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should not call onMessage', ->
      expect(@inputNode.onMessage).not.to.have.been.called

    it 'should call response.status with a 403 and send', ->
      expect(@response.status).to.have.been.calledWith 403
      expect(@response.end).to.have.been.called
