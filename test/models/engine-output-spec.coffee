EngineOutput = require '../../src/models/engine-output'
{PassThrough} = require 'stream'

describe 'EngineOutput', ->
  describe 'when we pipe the envelopeStream and pipe it to the sut', ->
    beforeEach (done) ->
      metadata =

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
      @envelopeStream = new PassThrough objectMode: true
      @envelopeStream.pipe @sut
      @envelopeStream.write envelope, done

    it 'should instantiate MeshbluHTTP with the config', ->
      expect(@MeshbluHttp).to.have.been.calledWithNew
      expect(@MeshbluHttp).to.have.been.calledWith uuid: 'flow-uuid', token: 'flow-token', raw: true

    it 'should call meshbluHttp.message with the message', ->
      expect(@meshbluHttpMessage).to.have.been.calledWith
        devices: ['*']
        topic: 'something-yellow'
        payload: {foo: 'bar'}
