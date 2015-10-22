{PassThrough} = require 'stream'
DatastoreCheckKeyStream = require '../../src/models/datastore-check-key-stream'
_ = require 'lodash'

describe 'DatastoreCheckKeyStream', ->
  describe 'the key exists', ->
    beforeEach (done) ->
      @datastore = exists: sinon.stub()
      @datastore.exists.withArgs('pulse:flow-uuid').yields null, 1
      metadata =
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'

      @sut = new DatastoreCheckKeyStream metadata, datastore: @datastore

      @sut.on 'data', (@result) => done()
      @sut.write dont: 'lose me'

    it 'should get some data', ->
      expect(@result).to.deep.equal dont: 'lose me'

  describe 'the key does not exist', ->
    beforeEach (done) ->
      @datastore = exists: sinon.stub()
      @datastore.exists.withArgs('pulse:flow-uuid').yields null, 0
      metadata =
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'

      @sut = new DatastoreCheckKeyStream metadata, datastore: @datastore

      @sut.on 'data', (@result) => done()
      @sut.write dont: 'lose me', done

    it 'should not get some data', ->
      expect(@result).to.not.exist
