EngineToNanocyteStream = require '../../src/models/engine-to-nanocyte-stream'

describe 'EngineToNanocyteStream', ->
  describe 'when instantiated with metadata', ->
    beforeEach ->
      @datastore =
        hget: sinon.stub()

      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/engine-data/config').yields null,
        {'node-instance-uuid': {nodeId: 'node-uuid'}}
      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/node-instance-uuid/config').yields null,
        {foo: 'bar'}
      @datastore.hget.withArgs('flow-uuid', 'instance-uuid/node-uuid/data').yields null,
        {is: 'data'}

    beforeEach ->
      metadata =
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'

      @sut = new EngineToNanocyteStream metadata, datastore: @datastore

    describe 'when a message is written to it', ->
      beforeEach (done) ->
        @sut.write {dont: 'lose me'}
        @sut.on 'data', (@result) => done()

      it 'should return the nanocyte envelope with config, data, and the message', ->
        expect(@result).to.deep.equal
          config:  {foo: 'bar'}
          data:    {is: 'data'}
          message: {dont: 'lose me'}

  describe 'when instantiated with a different envelope', ->
    beforeEach ->
      @datastore = hget: sinon.stub()
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/engine-data/config').yields null,
        {'the-node-instance-uuid': {nodeId: 'the-node-uuid'}}
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/the-node-instance-uuid/config').yields null,
        {foo: 'bar'}
      @datastore.hget.withArgs('the-flow-uuid', 'the-instance-uuid/the-node-uuid/data').yields null,
        {is: 'data'}

    beforeEach ->
      metadata =
        flowId: 'the-flow-uuid'
        instanceId: 'the-instance-uuid'
        toNodeId: 'the-node-instance-uuid'

      @sut = new EngineToNanocyteStream metadata, datastore: @datastore

    describe 'when a different message is written to it', ->
      beforeEach (done) ->
        @sut.write {do: 'lose me now'}
        @sut.on 'data', (@result) => done()

      it 'should return the nanocyte envelope with config, data, and the message', ->
        expect(@result).to.deep.equal
          message: {do: 'lose me now'}
          config:  {foo: 'bar'}
          data:    {is: 'data'}
