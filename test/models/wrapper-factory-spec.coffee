WrapperFactory = require '../../src/models/wrapper-factory'

describe 'WrapperFactory', ->
  describe 'when instantiated with one node that yields a: 1', ->
    beforeEach ->
      @wrapper1 = onEnvelope: sinon.stub().yields null, a: 1
      @sut = new WrapperFactory wrappers: [@wrapper1]

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal a: 1

  describe 'when instantiated with one node that yields b: 2', ->
    beforeEach ->
      @wrapper1 = onEnvelope: sinon.stub().yields null, b: 2
      @sut = new WrapperFactory wrappers: [@wrapper1]

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal b: 2

  describe 'when instantiated with two nodes', ->
    beforeEach ->
      @wrapper1 = onEnvelope: sinon.stub().yields null, b: 2
      @wrapper2 = onEnvelope: sinon.stub().yields null, c: 3
      @sut = new WrapperFactory wrappers: [@wrapper1, @wrapper2]

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should call Node2 with the output of Node1', ->
        expect(@wrapper1.onEnvelope).to.have.been.calledWith null

      it 'should call Node2 with the output of Node1', ->
        expect(@wrapper2.onEnvelope).to.have.been.calledWith b: 2

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal c: 3

  describe 'when instantiated with 2 nodes in a different order', ->
    beforeEach (done) ->
      @wrapper1 = onEnvelope: sinon.stub().yields null, d: 5
      @wrapper2 = onEnvelope: sinon.stub().yields null, e: 7
      @sut = new WrapperFactory wrappers: [@wrapper2, @wrapper1]
      @sut.onEnvelope {foo: 'bar'}, (error, @result) => done()

    it 'should call node2 with first argument of onEnvelope', ->
      expect(@wrapper2.onEnvelope).to.have.been.calledWith foo: 'bar'

    it 'should call node1 with the output of node2', ->
      expect(@wrapper1.onEnvelope).to.have.been.calledWith e: 7

  describe 'when instantiated with 3 nodes', ->
    beforeEach (done) ->
      @wrapper1 = onEnvelope: sinon.stub().yields null, f: 8
      @wrapper2 = onEnvelope: sinon.stub().yields null, g: 9
      @wrapper3 = onEnvelope: sinon.stub().yields null, h: 10
      @sut = new WrapperFactory wrappers: [@wrapper1, @wrapper2, @wrapper3]
      @sut.onEnvelope {foo: 'bar'}, (error, @result) => done()

    it 'should call node2 with first argument of onEnvelope', ->
      expect(@wrapper3.onEnvelope).to.have.been.calledWith g: 9
