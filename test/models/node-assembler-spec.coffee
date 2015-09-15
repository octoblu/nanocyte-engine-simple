_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @NanocyteNodeWrapper = sinon.spy =>
        onEnvelope: true

      @NanocyteDebug = sinon.spy =>
        onMessage: true

      @sut = new NodeAssembler {},
        NanocyteNodeWrapper: @NanocyteNodeWrapper
        NanocyteDebug: @NanocyteDebug

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

    it 'should construct a NanoCyteNodeWrapper with the debug node', ->
      expect(@NanocyteNodeWrapper).to.have.been.calledWith @NanocyteDebug
