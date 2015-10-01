Datastore = require '../../src/models/datastore'

describe 'Datastore', ->
  describe '->hget', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = hget: sinon.stub().yields null, '{"foo":"bar"}'
        @sut = new Datastore client: @client
        @sut.hget 'test', 'green-means-grow', (error, @result) =>

      it 'should call @client.hget with key and field', ->
        expect(@client.hget).to.have.been.calledWith 'test', 'green-means-grow'

      it 'should parse the json', ->
        expect(@result).to.deep.equal foo: 'bar'

    describe 'when given some barfu', ->
      beforeEach ->
        @client = hget: sinon.stub().yields null, '{"bar":"fu"}'
        @sut = new Datastore client: @client
        @sut.hget 'test', 'amoralism', (error, @result) =>

      it 'should call @client.hget with key and field', ->
        expect(@client.hget).to.have.been.calledWith 'test', 'amoralism'

      it 'should parse the json', ->
        expect(@result).to.deep.equal bar: 'fu'

  describe '->hset', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = hset: sinon.stub().yields null
        @sut = new Datastore client: @client
        @sut.hset 'test', 'path', 'best', (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.hset).to.have.been.calledWith 'test', 'path','"best"'

    describe 'when given an object', ->
      beforeEach ->
        @client = hset: sinon.stub().yields null
        @sut = new Datastore client: @client
        @sut.hset 'test', 'other-path', {'best':'foods'}, (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.hset).to.have.been.calledWith 'test', 'other-path', '{"best":"foods"}'
