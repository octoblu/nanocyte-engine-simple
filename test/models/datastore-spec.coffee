Datastore = require '../../src/models/datastore'

describe 'Datastore', ->
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

  describe '->getAndIncrementCount', ->
    describe 'when called', ->
      beforeEach ->
        @multi =
          incr:   sinon.stub()
          expire: sinon.stub()
          exec:   sinon.stub()

        @client =
          get:   sinon.stub()
          multi: sinon.stub()

        @callback = sinon.spy()
        @sut = new Datastore {}, client: @client
        @sut.getAndIncrementCount "some-key", @callback

      it 'should call datastore.get', ->
        expect(@client.get).to.have.been.calledWith "some-key"

      describe 'when client.get yields nothing', ->
        beforeEach ->
          @multi.incr.returns @multi
          @multi.expire.returns @multi
          @client.multi.returns @multi
          @client.get.yield()

        it 'should call datastore.multi', ->
          expect(@client.multi).to.have.been.called

        it 'should call datastore.multi.incr', ->
          expect(@multi.incr).to.have.been.calledWith 'some-key'

        it 'should call datastore.multi.expire', ->
          expect(@multi.expire).to.have.been.calledWith 'some-key', 10

        it 'should call datastore.multi.exec', ->
          expect(@multi.exec).to.have.been.called

        describe 'when exec yields', ->
          beforeEach ->
            @multi.exec.yield null

          it 'should call the callback with nothing', ->
            expect(@callback).to.have.been.calledWith null

      describe 'when client.get yields a count', ->
        beforeEach ->
          @multi.incr.returns @multi
          @multi.expire.returns @multi
          @client.multi.returns @multi
          @client.get.yield null, 4

        it 'should call datastore.multi', ->
          expect(@client.multi).to.have.been.called

        it 'should call datastore.multi.incr', ->
          expect(@multi.incr).to.have.been.calledWith 'some-key'

        it 'should call datastore.multi.expire', ->
          expect(@multi.expire).to.have.been.calledWith 'some-key', 10

        it 'should call datastore.multi.exec', ->
          expect(@multi.exec).to.have.been.called

        describe 'when exec yields', ->
          beforeEach ->
            @multi.exec.yield null

          it 'should call the callback with the count', ->
            expect(@callback).to.have.been.calledWith null, 4

      describe 'when client.get yields an error', ->
        beforeEach ->
          @error = new Error 'Slow-turning Windmill'
          @client.get.yield @error

        it 'should yield the error', ->
          expect(@callback).to.have.been.calledWith @error
