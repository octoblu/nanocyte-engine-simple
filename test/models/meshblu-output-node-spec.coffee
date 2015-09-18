MeshbluOutputNode = require '../../src/models/meshblu-output-node'

describe 'MeshbluOutputNode', ->
  describe '->onMessage', ->
    beforeEach ->
      @meshbluHttpMessage = sinon.spy => @meshbluHttpMessage.done()

      MeshbluHttp = require 'meshblu-http'
      MeshbluHttp.prototype.message = @meshbluHttpMessage

      @datastore = get: sinon.stub()
      @sut = new MeshbluOutputNode datastore: @datastore
      @sut.onMessage
        flowId: 'some-flow-uuid'
        instanceId: 'another-instance-id'
        fromNodeId: 'some-trigger-uuid'
        toNodeId: 'engine-output'
        message: 'boo'

    describe 'on successful request', ->
      beforeEach (done) ->
        @meshbluHttpMessage.done = done
        @datastore.get.yield null, anything: 'i want'

      it 'should call get on the datastore', ->
        expect(@datastore.get).to.have.been.calledWith 'some-flow-uuid/another-instance-id/engine-output/config'

      it 'should call MeshbluHttp.message', ->
        expect(@meshbluHttpMessage).to.have.been.calledWith
          devices: ["some-flow-uuid"]
          topic: 'debug'
          payload:
            node: 'some-trigger-uuid',
            msg:
              payload: 'boo'
