_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      class NanocyteNodeWrapper
        constructor: ({nodeClass: @nodeClass}) ->
        onEnvelope: sinon.spy()

      @NanocyteNodeWrapper = sinon.spy NanocyteNodeWrapper

      @OutputNodeWrapper = sinon.spy =>
        onEnvelope: sinon.spy()

      @DebugNode = sinon.spy =>
        onMessage: sinon.spy()

      @TriggerNode = sinon.spy =>
        onMessage: sinon.spy()

      @OutputNode = sinon.spy =>
        onMessage: sinon.spy()

      @sut = new NodeAssembler {},
        NanocyteNodeWrapper: @NanocyteNodeWrapper
        OutputNodeWrapper: @OutputNodeWrapper
        DebugNode: @DebugNode
        TriggerNode: @TriggerNode
        OutputNode: @OutputNode

      @nodes = @sut.assembleNodes()

    it 'should return something', ->
      expect(@nodes).not.to.be.empty

    it 'should return an object with keys for each node', ->
      expect(@nodes).to.have.all.keys [
        'nanocyte-node-debug'
        'nanocyte-node-trigger'
        'meshblu-output'
      ]

    it 'should return wrappers for each node', ->
      _.each @nodes, (node) =>
        expect(node.onEnvelope).to.exist

    it 'should return a nanocyte-node-wrapper for the debug node', ->
      node = @nodes['nanocyte-node-debug']
      expect(node).to.be.an.instanceOf @NanocyteNodeWrapper

    it 'should pass the debug node class to the node wrapper', ->
      node = @nodes['nanocyte-node-debug']
      expect(node.nodeClass).to.equal @DebugNode

    it 'should return a nanocyte-node-wrapper for the trigger node', ->
      node = @nodes['nanocyte-node-trigger']
      expect(node).to.be.an.instanceOf @NanocyteNodeWrapper

    it 'should pass the trigger node class to the node wrapper', ->
      node = @nodes['nanocyte-node-trigger']
      expect(node.nodeClass).to.equal @TriggerNode

    it 'should construct an OutputNodeWrapper with an OutputNode class', ->
      expect(@OutputNodeWrapper).to.have.been.calledWith nodeClass: @OutputNode
