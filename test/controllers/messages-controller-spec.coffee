MessagesController = require '../../src/controllers/messages-controller'

describe '/messages', ->
  beforeEach ->
    engineInput = @engineInput =
      message: sinon.spy()

    class EngineInput
      constructor: ->
      message: engineInput.message

    @response =
      status: sinon.spy => @response
      end: sinon.spy => @response

    @sut = new MessagesController EngineInput: EngineInput

  describe 'when /messages receives an authorized message', ->
    beforeEach ->
      request =
        header: sinon.stub().returns 'some-flow-uuid'
        params:
          flowId: 'some-flow-uuid'
          instanceId: 'some-instance-uuid'        
        body:
          foo: 'bar'

      @sut.create request, @response

    it 'should call message on the appropriate node', ->
      expect(@engineInput.message).to.have.been.calledWith
        foo: 'bar'
        flowId: 'some-flow-uuid'
        instanceId: 'some-instance-uuid'

    it 'should call response.status with a 201 and send', ->
      expect(@response.status).to.have.been.calledWith 201
      expect(@response.end).to.have.been.called

  describe 'when /messages receives a different authorized message', ->
    beforeEach ->
      request =
        header: sinon.stub().returns 'some-other-flow-uuid'
        params:
          flowId:     'some-other-flow-uuid'
          instanceId: 'some-instance-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should call message on the appropriate node', ->
      expect(@engineInput.message).to.have.been.calledWith
        shoe: 'spar'
        flowId: 'some-other-flow-uuid'
        instanceId: 'some-instance-uuid'

  describe 'when /messages receives a different authorized message from the wrong uuid', ->
    beforeEach ->
      request =
        header: sinon.stub().returns 'wrong-uuid'
        params:
          flowId:     'some-other-flow-uuid'
          instanceId: 'some-instance-uuid'
        body:
          shoe: 'spar'

      @sut.create request, @response

    it 'should not call message', ->
      expect(@engineInput.message).not.to.have.been.called

    it 'should call response.status with a 403 and send', ->
      expect(@response.status).to.have.been.calledWith 403
      expect(@response.end).to.have.been.called
