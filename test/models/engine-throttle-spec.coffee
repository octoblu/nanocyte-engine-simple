EngineThrottle = require '../../src/models/engine-throttle'
_ = require 'lodash'

describe 'EngineThrottle', ->
  it 'should exist', ->
    new EngineThrottle

  describe 'when a message is written to it', ->
    beforeEach ->
      @datastore = getAndIncrementCount: sinon.stub()

      @moment = => unix: => 12345

      @sut = new EngineThrottle {}, datastore: @datastore, moment: @moment

      envelope =
        config:
          uuid: 'user-uuid'
        message:
          devices: ['some-other-uuid']
          payload:
            msg: 'hello world'
            node: 'some-node-uuid'

      @sut.write envelope

    it 'should call datastore.getAndIncrementCount', ->
      expect(@datastore.getAndIncrementCount).to.have.been.calledWith "user-uuid:12345"

    describe 'when datastore.getAndIncrementCount yields nothing', ->
      beforeEach (done) ->
        @things = []

        @sut.on 'readable', =>
          while thing = @sut.read()
            @things.push thing
          done()

        @datastore.getAndIncrementCount.yield()

      it 'should pass-through the message', ->
        expect(@things).to.have.a.lengthOf 1
        expect(_.first @things).to.deep.equal
          config:
            uuid: 'user-uuid'
          message:
            devices: ['some-other-uuid']
            payload:
              msg: 'hello world'
              node: 'some-node-uuid'

    describe 'when datastore.getAndIncrementCount yields 10', ->
      beforeEach (done) ->
        @things = []

        @sut.on 'readable', =>
          while thing = @sut.read()
            @things.push thing
          done()

        @datastore.getAndIncrementCount.yield null, 10

      it 'should emit an error message', ->
        expect(@things).to.have.a.lengthOf 1
        expect(_.first @things).to.deep.equal
          config:
            uuid: 'user-uuid'
          message:
            devices: ['*']
            topic:   'debug'
            payload:
              msgType: 'error'
              msg: 'Engine rate limit exceeded'
              node: 'some-node-uuid'

    describe 'when datastore.getAndIncrementCount yields 11', ->
      beforeEach (done) ->
        @things = []

        @sut.on 'readable', =>
          while thing = @sut.read()
            @things.push thing
          done()

        @datastore.getAndIncrementCount.yield null, 11

      it 'should emit nothing!', ->
        expect(@things).to.be.empty
