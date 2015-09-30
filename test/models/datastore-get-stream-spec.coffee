{PassThrough} = require 'stream'
DatastoreGetStream = require '../../src/models/datastore-get-stream'

describe 'DatastoreGetStream', ->
  describe 'when instantiated with an envelope', ->
    beforeEach (done) ->
      @datastore = hget: sinon.stub()
      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/engine-data/config').yields null,
        {'node-instance-uuid': {nodeId: 'node-uuid'}}
      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/node-instance-uuid/config').yields null,
        {foo: 'bar'}
      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/node-uuid/data').yields null,
        {is: 'data'}

      @sut = new DatastoreGetStream {}, datastore: @datastore
      @sut.on 'readable', =>
        @result = @sut.read()
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
        config:  {foo: 'bar'}
        data:    {is: 'data'}

  describe 'when instantiated with a different envelope', ->
    beforeEach (done) ->
      @datastore = hget: sinon.stub()
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/engine-data/config').yields null,
        {'the-node-instance-uuid': {nodeId: 'the-node-uuid'}}
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/the-node-instance-uuid/config').yields null,
        {foo: 'bar'}
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/the-node-uuid/data').yields null,
        {is: 'data'}

      @sut = new DatastoreGetStream {}, datastore: @datastore
      @sut.on 'readable', =>
        @result = @sut.read()
        done()

      @envelopeInStream = new PassThrough objectMode: true
      @envelopeInStream.pipe(@sut)
      @envelopeInStream.write
        flowId: 'the-flow-uuid'
        instanceId: 'the-instance-uuid'
        toNodeId: 'the-node-instance-uuid'
        message: {do: 'lose me now'}

    it 'should get some data', ->
      expect(@result).to.deep.equal
        flowId: 'the-flow-uuid'
        instanceId: 'the-instance-uuid'
        toNodeId: 'the-node-instance-uuid'
        message: {do: 'lose me now'}
        config:  {foo: 'bar'}
        data:    {is: 'data'}
