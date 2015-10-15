NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'
stream = require 'stream'
_ = require 'lodash'

describe 'NanocyteNodeWrapper', ->
  describe 'on write', ->
    beforeEach ->
      @mahNodeOnWrite = mahNodeOnWrite = sinon.stub().yields()
      class MahNode extends stream.Writable
        constructor: ->
          super objectMode: true

        write: mahNodeOnWrite

      @sut = new NanocyteNodeWrapper nodeClass: MahNode
      @sut.initialize()

    describe 'when an envelope is written to it', ->
      beforeEach (done) ->
        @sut.write flowId: 5, config: {contains: 'config'}, data: {is: 'data'}, message: {foo: 'bar'}, done

      it 'should call onMessage on MahNode', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {contains: 'config'}
          data: {is: 'data'}
          message: {foo: 'bar'}

    describe 'when an envelope with templating is written to it', ->
      beforeEach (done) ->
        @sut.write flowId: 5, config: {foo: "{{bar}}"}, data: {}, message: {bar: 'duck'}, done

      it 'should call onMessage on MahNode after running through christacheio', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {foo: 'duck'}
          data: {}
          message: {bar: 'duck'}

    describe 'I think this is why we double pass', ->
      beforeEach (done) ->
        envelope =
          config: {duckGoes: "{{bar}}"}
          data: {}
          message: {bar: '{{sound}}', sound: 'quack'}

        @sut.write envelope, done

      it 'should call onMessage on MahNode after running through christacheio twice', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {duckGoes: 'quack'}
          data: {}
          message: {bar: '{{sound}}', sound: 'quack'}

    describe 'when a non-string is passed in', ->
      beforeEach (done) ->
        envelope =
          config: {duckCounts: "{{foo}}"}
          data: {}
          message: {foo: [1,2,3]}

        @sut.write envelope, done

      it 'should call onMessage on MahNode with the array', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {duckCounts: [1,2,3]}
          data: {}
          message: {foo: [1,2,3]}

    describe 'when nesting the key under msg', ->
      beforeEach (done) ->
        envelope =
          config: {duckCounts: "{{msg.foo}}"}
          data: {}
          message: {foo: [1,2,3]}

        @sut.write envelope, done

      it 'should call onMessage on MahNode with the array', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {duckCounts: [1,2,3]}
          data: {}
          message: {foo: [1,2,3]}

  describe 'on read', ->
    describe 'when mah node only emits one message', ->
      beforeEach ->
        class MahNode extends stream.Duplex
          constructor: ->
            super objectMode: true

          _write: (a, b, next)=>
            @push 5
            next()

          _read: () =>
            5

        @sut = new NanocyteNodeWrapper nodeClass: MahNode
        @sut.initialize()

      describe 'when an envelope is written to it', ->
        beforeEach (done) ->
          @sut.on 'data', (result) =>
            @result = result
            done()

          @sut.write flowId: 555, toNodeId: 7, config: {}, message: {}

        it 'should emit an envelope', ->
          expect(@result).to.deep.equal
            flowId: 555
            fromNodeId: 7
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
        @sut.initialize()

      describe 'when an envelope is written to it', ->
        beforeEach (done) ->
          @results = []

          @sut.write flowId: 555, toNodeId: 3, config: {}, message: {}
          @sut.on 'data', (result) => @results.push result
          @sut.on 'end', done

        it 'should emit the first message', ->
          expect(@results).to.deep.contain
            flowId: 555
            fromNodeId: 3
            message: 1

        it 'should emit the second message', ->
          expect(@results).to.deep.contain
            flowId: 555
            fromNodeId: 3
            message: 2

  describe 'on explode', ->
    beforeEach ->
      class WaffleIron extends stream.Writable
        constructor: ->
          super objectMode: true

        write: =>
          _.defer =>
            throw new Error 'Batter up!'

      @sut = new NanocyteNodeWrapper nodeClass: WaffleIron
      @sut.initialize()

    describe 'when written to', ->
      beforeEach (done) ->
        @callback = (@error) => done()
        @sut.on 'error', @callback
        @sut.write
          message: 'hi'
          config: {}

      it 'should have emitted the error', ->
        expect(=> throw @error).to.throw 'Batter up!'

  describe 'on a smaller explosion', ->
    beforeEach ->
      class Timber extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: =>
          _.defer => throw new Error 'You WOOD die this way.'

      @sut = new NanocyteNodeWrapper nodeClass: Timber
      @sut.initialize()

    describe 'when written to', ->
      beforeEach (done) ->
        @sut.on 'data', =>
        @sut.on 'error', (@error) => done()
        @sut.write message: 'hi', config: {}

      it 'should have emitted the error', ->
        expect(=> throw @error).to.throw 'You WOOD die this way.'

  describe 'on a node constructor explosion', ->
    beforeEach (done) ->
      class ChoppedToBits
        constructor: ->
          throw new Error 'Look at the bright side -- you avoided being ground into dust!'

      @sut = new NanocyteNodeWrapper nodeClass: ChoppedToBits
      @sut.on 'error', (@error) => done()
      @sut.initialize()

    it 'should have emitted the error', ->
      expect(=> throw @error).to.throw 'Look at the bright side -- you avoided being ground into dust!'
