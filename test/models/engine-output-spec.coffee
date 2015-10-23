EngineOutput = require '../../src/models/engine-output'
{PassThrough} = require 'stream'

describe 'EngineOutput', ->
  describe 'when we write to the sut', ->
    beforeEach (done) ->
      envelope =
        message:
          devices: ['*']
          topic: 'something-yellow'
          payload: {foo: 'bar'}
        config:
          uuid: 'flow-uuid'
          token: 'flow-token'

      @meshbluHttpMessage = sinon.spy()
      @MeshbluHttp = sinon.spy => message: @meshbluHttpMessage

      @sut = new EngineOutput {}, MeshbluHttp: @MeshbluHttp
      @sut.write envelope
      @sut.on 'data', =>
      @sut.on 'end', done

    it 'should instantiate MeshbluHTTP with the config', ->
      expect(@MeshbluHttp).to.have.been.calledWithNew
      expect(@MeshbluHttp).to.have.been.calledWith uuid: 'flow-uuid', token: 'flow-token'

    it 'should call meshbluHttp.message with the message', ->
      expect(@meshbluHttpMessage).to.have.been.calledWith
        devices: ['*']
        topic: 'something-yellow'
        payload: {foo: 'bar'}
