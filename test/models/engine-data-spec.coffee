EngineData = require '../../src/models/engine-data'

describe 'EngineData', ->
  beforeEach ->
    @datastore = hset: sinon.stub()

  describe 'when constructed with some metadata', ->
    beforeEach ->
      metadata =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'node-instance-id'
        toNodeId: 'engine-data'

      @sut = new EngineData metadata, datastore: @datastore

    describe 'when an envelope is written to it', ->
      beforeEach (done)->
        envelope =
          message: 'foo'
          config:
            'node-instance-id': {nodeId: 'node-id'}

        @sut.write envelope

        @sut.on 'data', =>
        @sut.on 'end', done

      it 'should save the message', ->
        expect(@datastore.hset).to.have.been.calledWith(
          'flow-id'
          'instance-id/node-id/data'
          'foo'
        )

  describe 'when constructed with differenter metadata', ->
    beforeEach ->
      metadata =
        flowId: 'the-flow-id'
        instanceId: 'the-instance-id'
        fromNodeId: 'the-node-instance-id'
        toNodeId: 'engine-data'

      @sut = new EngineData metadata, datastore: @datastore

    describe 'when an envelope is written to it', ->
      beforeEach ->
        @sut.write
          message: baz: 'bar'
          config:
            'the-node-instance-id': {nodeId: 'the-node-id'}

      it 'should save the message', ->
        expect(@datastore.hset).to.have.been.calledWith(
          'the-flow-id'
          'the-instance-id/the-node-id/data'
          baz: 'bar'
        )

  describe 'when constructed for a configless node', ->
    beforeEach ->
      metadata =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'nope'
        toNodeId: 'engine-data'

      @sut = new EngineData metadata, datastore: @datastore

    describe 'when an envelope is written to it', ->
      beforeEach ->
        @sut.write
          message: 'irrelevent'
          config: {}

      it 'should not call hset', ->
        expect(@datastore.hset).not.to.have.been.called
