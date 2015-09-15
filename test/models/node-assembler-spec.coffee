_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @NanocyteNodeWrapper = sinon.spy =>
        onEnvelope: sinon.spy()

      @OutputNodeWrapper = sinon.spy =>
        onEnvelope: sinon.spy()

      @DebugNode = sinon.spy =>
        onMessage: sinon.spy()

      @OutputNode = sinon.spy =>
        onMessage: sinon.spy()

      @sut = new NodeAssembler {},
        NanocyteNodeWrapper: @NanocyteNodeWrapper
        OutputNodeWrapper: @OutputNodeWrapper
        DebugNode: @DebugNode
        OutputNode: @OutputNode

      @nodes = @sut.assembleNodes()

    it 'should return something', ->
      expect(@nodes).not.to.be.empty

    it 'should return an object with keys for each node', ->
      expect(@nodes).to.have.all.keys [
        'nanocyte-node-debug'
        'meshblu-output'
      ]

    it 'should return wrappers for each node', ->
      _.each @nodes, (node) =>
        expect(node.onEnvelope).to.exist

    it 'should return a nanocyte-node-wrapper for the debug node', ->
      expect(@NanocyteNodeWrapper).to.have.been.calledWithNew

    it 'should construct an OutputNodeWrapper with an OutputNode class', ->
      expect(@OutputNodeWrapper).to.have.been.calledWith @OutputNode
