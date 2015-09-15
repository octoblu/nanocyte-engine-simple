WrapperFactory = require '../../src/models/wrapper-factory'

class Node1
  constructor: (@config, @data) ->
  onEnvelope: (message, callback) =>

class Node2
  constructor: (@config, @data) ->
  onEnvelope: (message, callback) =>

class Node3
  constructor: (@config, @data) ->
  onEnvelope: (message, callback) =>

describe 'WrapperFactory', ->
  describe 'when instantiated with one node that yields a: 1', ->
    beforeEach ->
      Node1.prototype.onEnvelope = sinon.stub().yields null, a: 1
      @nodes = [Node1]
      @sut = new WrapperFactory nodeClasses: @nodes

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal a: 1

  describe 'when instantiated with one node that yields b: 2', ->
    beforeEach ->
      Node1.prototype.onEnvelope = sinon.stub().yields null, b: 2
      @nodes = [Node1]
      @sut = new WrapperFactory nodeClasses: @nodes

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal b: 2

  describe 'when instantiated with two nodes', ->
    beforeEach ->
      Node1.prototype.onEnvelope = sinon.stub().yields null, b: 2
      Node2.prototype.onEnvelope = sinon.stub().yields null, c: 3
      @sut = new WrapperFactory nodeClasses: [Node1, Node2]

    describe 'when onEnvelope is called', ->
      beforeEach (done) ->
        @sut.onEnvelope null, (@error, @result) => done()

      it 'should call Node2 with the output of Node1', ->
        expect(Node1.prototype.onEnvelope).to.have.been.calledWith null

      it 'should call Node2 with the output of Node1', ->
        expect(Node2.prototype.onEnvelope).to.have.been.calledWith b: 2

      it 'should yield the output of the last node in the chain', ->
        expect(@result).to.deep.equal c: 3

  describe 'when instantiated with 2 nodes in a different order', ->
    beforeEach (done) ->
      Node1.prototype.onEnvelope = sinon.stub().yields null, d: 5
      Node2.prototype.onEnvelope = sinon.stub().yields null, e: 7
      @sut = new WrapperFactory nodeClasses: [Node2, Node1]
      @sut.onEnvelope {foo: 'bar'}, (error, @result) => done()

    it 'should call node2 with first argument of onEnvelope', ->
      expect(Node2.prototype.onEnvelope).to.have.been.calledWith foo: 'bar'

    it 'should call node1 with the output of node2', ->
      expect(Node1.prototype.onEnvelope).to.have.been.calledWith e:7

  describe 'when instantiated with 3 nodes', ->
    beforeEach (done) ->
      Node1.prototype.onEnvelope = sinon.stub().yields null, f: 8
      Node2.prototype.onEnvelope = sinon.stub().yields null, g: 9
      Node3.prototype.onEnvelope = sinon.stub().yields null, h: 10
      @sut = new WrapperFactory nodeClasses: [Node1, Node2, Node3]
      @sut.onEnvelope {foo: 'bar'}, (error, @result) => done()

    it 'should call node2 with first argument of onEnvelope', ->
      expect(Node3.prototype.onEnvelope).to.have.been.calledWith g: 9
