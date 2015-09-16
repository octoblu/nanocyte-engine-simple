NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'
stream = require 'stream'

describe 'NanocyteNodeWrapper', ->
  describe 'on write', ->
    beforeEach ->
      @mahNodeOnWrite = mahNodeOnWrite = sinon.stub().yields()
      class MahNode extends stream.Writable
        constructor: ->
          super objectMode: true

        write: mahNodeOnWrite

      @sut = new NanocyteNodeWrapper nodeClass: MahNode

    describe 'when an envelope is written to it', ->
      beforeEach (done) ->
        @sut.write flowId: 5, config: {contains: 'config'}, data: {is: 'data'}, message: {foo: 'bar'}, done

      it 'should call onMessage on MahNode', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {contains: 'config'}
          data: {is: 'data'}
          message: {foo: 'bar'}

  describe 'on read', ->
    describe 'when mah node only emits one message', ->
      beforeEach ->
        class MahNode extends stream.Duplex
          constructor: ->
            super objectMode: true

          _write: (a, b, next)=>
            next()
            @emit 'readable'

          read: =>
            5

        @sut = new NanocyteNodeWrapper nodeClass: MahNode

      describe 'when an envelope is written to it', ->
        beforeEach (done) ->
          @sut.on 'readable', =>
            @result = @sut.read()
            done()

          @sut.write flowId: 555

        it 'should call onMessage on MahNode', ->
          expect(@result).to.deep.equal
            flowId: 555
            message: 5

    describe 'when mah node emits two messages', ->
      beforeEach ->
        class TwoMessageNode extends stream.Transform
          constructor: ->
            super objectMode: true

          _transform: (a, b, next) =>
            @push 1
            @push 2
            @push null
            next()

        @sut = new NanocyteNodeWrapper nodeClass: TwoMessageNode

      describe 'when an envelope is written to it', ->
        beforeEach (done) ->
          @results = []

          @sut.write flowId: 555
          @sut.on 'readable', =>
            while result = @sut.read()
              @results.push result

          @sut.on 'end', done

        it 'should emit the first message', ->
          expect(@results).to.deep.contain
            flowId: 555
            message: 1

        it 'should emit the second message', ->
          expect(@results).to.deep.contain
            flowId: 555
            message: 2
