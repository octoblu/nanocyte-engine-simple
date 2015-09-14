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
