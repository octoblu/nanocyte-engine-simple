{PassThrough} = require 'stream'
DatastoreGetStream = require '../../src/models/datastore-get-stream'

describe 'DatastoreGetStream', ->
  describe 'when instantiated with an envelope', ->
    beforeEach (done) ->
      @datastore = get: sinon.stub()
      @datastore.get.withArgs('flow-uuid/node-uuid/config').yields null, {foo: 'bar'}
      @datastore.get.withArgs('flow-uuid/node-uuid/data').yields null, {is: 'data'}

      @sut = new DatastoreGetStream {}, datastore: @datastore
      @sut.on 'readable', =>
        @result = @sut.read()
        done()

      @envelopeInStream = new PassThrough objectMode: true
      @envelopeInStream.pipe(@sut)
      @envelopeInStream.write flowId: 'flow-uuid', toNodeId: 'node-uuid', message: {dont: 'lose me'}

    it 'should get some data', ->
      expect(@result).to.deep.equal
        flowId: 'flow-uuid'
        toNodeId: 'node-uuid'
        message: {dont: 'lose me'}
        config:  {foo: 'bar'}
        data:    {is: 'data'}

  describe 'when instantiated with a different envelope', ->
    beforeEach (done) ->
      @datastore = get: sinon.stub()
      @datastore.get.withArgs('the-flow-uuid/the-node-uuid/config').yields null, {foo: 'bar'}
      @datastore.get.withArgs('the-flow-uuid/the-node-uuid/data').yields null, {is: 'data'}

      @sut = new DatastoreGetStream {}, datastore: @datastore
      @sut.on 'readable', =>
        @result = @sut.read()
        done()

      @envelopeInStream = new PassThrough objectMode: true
      @envelopeInStream.pipe(@sut)
      @envelopeInStream.write flowId: 'the-flow-uuid', toNodeId: 'the-node-uuid', message: {do: 'lose me now'}

    it 'should get some data', ->
      expect(@result).to.deep.equal
        flowId: 'the-flow-uuid'
        toNodeId: 'the-node-uuid'
        message: {do: 'lose me now'}
        config:  {foo: 'bar'}
        data:    {is: 'data'}
