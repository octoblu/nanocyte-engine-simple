{PassThrough} = require 'stream'
DatastoreCheckKeyStream = require '../../src/models/datastore-check-key-stream'
_ = require 'lodash'

describe 'DatastoreCheckKeyStream', ->
  describe 'the key exists', ->
    beforeEach (done) ->
      @datastore = exists: sinon.stub()
      @datastore.exists.withArgs('flow-uuid-pulse').yields null, 1

      @sut = new DatastoreCheckKeyStream {}, datastore: @datastore
      @sut.on 'readable', =>
        result = @sut.read()
        return if _.isNull result
        @result = result

      @sut.on 'end', =>
        done()

      @envelopeInStream = new PassThrough objectMode: true
      @envelopeInStream.pipe(@sut)
      @envelopeInStream.write
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'
        message: {dont: 'lose me'}

    it 'should get some data', ->
      expect(@result).to.deep.equal
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'
        message: {dont: 'lose me'}

  describe 'the key does not exist', ->
    beforeEach (done) ->
      @datastore = exists: sinon.stub()
      @datastore.exists.withArgs('flow-uuid-pulse').yields null, 0

      @sut = new DatastoreCheckKeyStream {}, datastore: @datastore
      @sut.on 'readable', =>
        result = @sut.read()
        return if _.isNull result
        @result = result

      @sut.on 'end', =>
        done()

      @envelopeInStream = new PassThrough objectMode: true
      @envelopeInStream.pipe(@sut)
      @envelopeInStream.write
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'
        message: {dont: 'lose me'}

    it 'should not get some data', ->
      expect(@result).to.not.exist
