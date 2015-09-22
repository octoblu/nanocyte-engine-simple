EngineData = require '../../src/models/engine-data'

describe 'EngineData', ->
  beforeEach ->
    @datastore = set: sinon.stub()
    @sut = new EngineData {}, datastore: @datastore

  describe 'when an envelope is written to it', ->
    beforeEach ->
      envelope =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'node-instance-id'
        toNodeId: 'engine-data'
        message: 'foo'
        config:
          'node-instance-id': {nodeId: 'node-id'}

      @callback = sinon.spy()
      @sut.write envelope, @callback

    it 'should save the message', ->
      expect(@datastore.set).to.have.been.calledWith(
        'flow-id/instance-id/node-id/data'
        'foo'
      )

    describe 'when @datastore.set yields', ->
      beforeEach ->
        @datastore.set.yield null

      it 'should call our callback', ->
        expect(@callback).to.have.been.called

  describe 'when an differenter envelope is written to it', ->
    beforeEach ->
      @sut.write
        flowId: 'the-flow-id'
        instanceId: 'the-instance-id'
        fromNodeId: 'the-node-instance-id'
        toNodeId: 'engine-data'
        message: baz: 'bar'
        config:
          'the-node-instance-id': {nodeId: 'the-node-id'}

    it 'should save the message', ->
      expect(@datastore.set).to.have.been.calledWith(
        'the-flow-id/the-instance-id/the-node-id/data'
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

    it 'should not call set', ->
      expect(@datastore.set).not.to.have.been.called