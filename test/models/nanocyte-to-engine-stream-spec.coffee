NanocyteToEngineStream = require '../../src/models/nanocyte-to-engine-stream'

describe 'NanocyteToEngineStream', ->
  describe 'when instantiated with metadata', ->

    beforeEach ->
      metadata =
        flowId: 'flow-uuid'
        instanceId: 'instance-uuid'
        toNodeId: 'node-instance-uuid'
        fromNodeId: 'whatever'

      @sut = new NanocyteToEngineStream metadata, datastore: @datastore

    describe 'when a message is written to it', ->
      beforeEach (done) ->
        @sut.write {dont: 'lose me'}
        @sut.on 'data', (@result) => done()

      it 'should return the engine envelope with the message and correct metadata', ->
        expect(@result).to.deep.equal
          metadata:
            flowId: 'flow-uuid'
            instanceId: 'instance-uuid'
            fromNodeId: 'node-instance-uuid'
            
          message: {dont: 'lose me'}
