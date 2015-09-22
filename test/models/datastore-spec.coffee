Datastore = require '../../src/models/datastore'

describe 'Datastore', ->
  describe '->get', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = get: sinon.stub().yields null, '{"foo":"bar"}'
        @sut = new Datastore client: @client
        @sut.get 'test', (error, @result) =>

      it 'should parse the json', ->
        expect(@result).to.deep.equal foo: 'bar'

    describe 'when given some barfu', ->
      beforeEach ->
        @client = get: sinon.stub().yields null, '{"bar":"fu"}'
        @sut = new Datastore client: @client
        @sut.get 'test', (error, @result) =>

      it 'should parse the json', ->
        expect(@result).to.deep.equal bar: 'fu'

  describe '->set', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = set: sinon.stub().yields null
        @sut = new Datastore client: @client
        @sut.set 'test', 'best', (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.set).to.have.been.calledWith 'test', '"best"'

    describe 'when given an object', ->
      beforeEach ->
        @client = set: sinon.stub().yields null
        @sut = new Datastore client: @client
        @sut.set 'test', {'best':'foods'}, (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.set).to.have.been.calledWith 'test', '{"best":"foods"}'
