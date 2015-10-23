EngineData = require '../../src/models/engine-data'

describe 'EngineData', ->
  beforeEach ->
    @datastore = hset: sinon.stub()
    @sut = new EngineData {}, datastore: @datastore

  describe 'when an envelope is written to it', ->
    beforeEach (done)->
      envelope =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'node-instance-id'
        toNodeId: 'engine-data'
        message: 'foo'
        config:
          'node-instance-id': {toNodeId: 'node-id'}

      @sut.write envelope

      @sut.on 'data', =>
      @sut.on 'end', done

    it 'should save the message', ->
      expect(@datastore.hset).to.have.been.calledWith(
        'flow-id'
        'instance-id/node-id/data'
        'foo'
      )

    describe 'when @datastore.hset yields', ->
      beforeEach ->
        @datastore.hset.yield null
      
  describe 'when an differenter envelope is written to it', ->
    beforeEach ->
      @sut.write
        flowId: 'the-flow-id'
        instanceId: 'the-instance-id'
        fromNodeId: 'the-node-instance-id'
        toNodeId: 'engine-data'
        message: baz: 'bar'
        config:
          'the-node-instance-id': {toNodeId: 'the-node-id'}

    it 'should save the message', ->
      expect(@datastore.hset).to.have.been.calledWith(
        'the-flow-id'
        'the-instance-id/the-node-id/data'
        baz: 'bar'
      )

  describe 'when the message is to a configless node', ->
    beforeEach ->
      @sut.write
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'nope'
        toNodeId: 'engine-data'
        message: 'irrelevent'
        config: {}

    it 'should not call hset', ->
      expect(@datastore.hset).not.to.have.been.called
