EngineBatch = require '../../src/models/engine-batch'
_ = require 'lodash'

describe 'EngineBatch', ->
  beforeEach ->
    delete EngineBatch.batches

  describe 'when we write to it', ->
    beforeEach ->
      @sut = new EngineBatch
      @sut.write
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'from-node-id'
        toNodeId: 'to-node-id'
        complications: 'its complicated'

    it 'should instaniate the global state and add the message', ->
      expect(_.size EngineBatch.batches).to.deep.deep.deep.equal 1
      expect(EngineBatch.batches['flow-id']).to.exist
      expect(EngineBatch.batches['flow-id'].envelopes).to.contain
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'from-node-id'
        toNodeId: 'to-node-id'
        complications: 'its complicated'

    it 'should contain the flowId in the global state object', ->
      expect(EngineBatch.batches['flow-id'].flowId).to.equal 'flow-id'
      expect(EngineBatch.batches['flow-id'].instanceId).to.equal 'instance-id'
      expect(EngineBatch.batches['flow-id'].toNodeId).to.equal 'to-node-id'

    describe 'when we write something else to the same flow id', ->
      beforeEach ->
        @sut = new EngineBatch
        @sut.write flowId: 'flow-id', angry: 'mob'

      it 'should push the message onto the global state', ->
        expect(_.size EngineBatch.batches).to.deep.deep.deep.equal 1
        expect(EngineBatch.batches['flow-id']).to.exist
        expect(EngineBatch.batches['flow-id'].envelopes).have.a.lengthOf 2
        expect(EngineBatch.batches['flow-id'].envelopes).to.contain
          flowId: 'flow-id'
          angry: 'mob'

    describe 'when we write something else to another flow id', ->
      beforeEach ->
        @sut = new EngineBatch
        @sut.write flowId: 'another-flow-id', tafty: 'bathtub'

      it 'should push the message onto the global state', ->
        expect(_.size EngineBatch.batches).to.deep.deep.deep.equal 2
        expect(EngineBatch.batches['another-flow-id']).to.exist
        expect(EngineBatch.batches['another-flow-id'].envelopes).to.contain
          flowId: 'another-flow-id'
          tafty: 'bathtub'
