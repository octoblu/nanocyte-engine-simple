_ = require 'lodash'
Datastore = require '../../src/models/datastore'

describe 'Datastore', ->
  describe '->setex', ->
    describe 'when given a key and timeout', ->
      beforeEach ->
        @client = setex: sinon.stub()
        @sut = new Datastore {}, client: @client
        @sut.setex 'foo', 1, 'val1',

      it 'should call @client.setex with key and timeout', ->
        expect(@client.setex).to.have.been.calledWith 'foo', 1, 'val1'

    describe 'when given a different key and timeout', ->
      beforeEach ->
        @client = setex: sinon.stub()
        @sut = new Datastore {}, client: @client
        @sut.setex 'bar', 2, 'val2'

      it 'should call @client.setex with key and timeout', ->
        expect(@client.setex).to.have.been.calledWith 'bar', 2, 'val2'

  describe '->exists', ->
    describe 'when given a key and timeout', ->
      beforeEach ->
        @client = exists: sinon.stub()
        @sut = new Datastore {}, client: @client
        @sut.exists 'foo'

      it 'should call @client.exists with key and timeout', ->
        expect(@client.exists).to.have.been.calledWith 'foo'

    describe 'when given a different key and timeout', ->
      beforeEach ->
        @client = exists: sinon.stub()
        @sut = new Datastore {}, client: @client
        @sut.exists 'bar'

      it 'should call @client.exists with key and timeout', ->
        expect(@client.exists).to.have.been.calledWith 'bar'

  describe '->hget', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = hget: sinon.stub().yields null, '{"foo":"bar"}'
        @sut = new Datastore {}, client: @client
        @sut.hget 'test', 'green-means-grow', (error, @result) =>

      it 'should call @client.hget with key and field', ->
        expect(@client.hget).to.have.been.calledWith 'test', 'green-means-grow'

      it 'should parse the json', ->
        expect(@result).to.deep.equal foo: 'bar'

    describe 'when given some barfu', ->
      beforeEach ->
        @client = hget: sinon.stub().yields null, '{"bar":"fu"}'
        @sut = new Datastore {}, client: @client
        @sut.hget 'test', 'amoralism', (error, @result) =>

      it 'should call @client.hget with key and field', ->
        expect(@client.hget).to.have.been.calledWith 'test', 'amoralism'

      it 'should parse the json', ->
        expect(@result).to.deep.equal bar: 'fu'

  describe '->hset', ->
    describe 'when given some foobar', ->
      beforeEach ->
        @client = hset: sinon.stub().yields null
        @sut = new Datastore {}, client: @client
        @sut.hset 'test', 'path', 'best', (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.hset).to.have.been.calledWith 'test', 'path','"best"'

    describe 'when given an object', ->
      beforeEach ->
        @client = hset: sinon.stub().yields null
        @sut = new Datastore {}, client: @client
        @sut.hset 'test', 'other-path', {'best':'foods'}, (error, @result) =>

      it 'should stringify the json and pass to the client', ->
        expect(@client.hset).to.have.been.calledWith 'test', 'other-path', '{"best":"foods"}'

    describe 'when given a huge message', ->
      beforeEach (done) ->
        @client = hset: sinon.stub().yields null
        @sut = new Datastore {}, client: @client
        messageSize = 1024 * 1024 * 10 # 10MB (probably)
        largeMessage = ""
        _.times messageSize, => largeMessage += 'a'
        @sut.hset 'test', 'other-path', largeMessage, (@error, @result) => done()

      it 'should set the data to null', ->
        expect(@client.hset).to.have.been.calledWith 'test', 'other-path', 'null'
        expect(=> throw @error).to.throw 'Message was too large'

  describe '->getAndIncrementCount', ->
    describe 'when called', ->
      beforeEach ->
        @multi =
          incr:   sinon.stub()
          expire: sinon.stub()
          exec:   sinon.stub()

        @multi.incr.returns @multi
        @multi.expire.returns @multi

        @client =
          multi: sinon.stub().returns @multi

        @callback = sinon.spy()
        @sut = new Datastore {}, client: @client
        @sut.getAndIncrementCount "some-key", @callback

      it 'should call datastore.multi', ->
        expect(@client.multi).to.have.been.called

      it 'should call datastore.multi.incr', ->
        expect(@multi.incr).to.have.been.calledWith 'some-key'

      it 'should call datastore.multi.expire', ->
        expect(@multi.expire).to.have.been.calledWith 'some-key', 10

      it 'should call datastore.multi.exec', ->
        expect(@multi.exec).to.have.been.called

      describe 'when exec yields the results', ->
        beforeEach ->
          @multi.exec.yield null, [1, true]

        it 'should call the callback with nothing', ->
          expect(@callback).to.have.been.calledWith null

      describe 'when exec yields an error', ->
        beforeEach ->
          @error = new Error 'Slow-turning Windmill'
          @multi.exec.yield @error, [1, true]

        it 'should yield the error', ->
          expect(@callback).to.have.been.calledWith @error
