EngineDebug = require '../../src/models/engine-debug'
{PassThrough} = require 'stream'

describe 'EngineDebug', ->
  describe 'when we pipe the envelopeStream and pipe it to the sut', ->
    beforeEach (done) ->
      envelope =
        message:
          some: 'data'
        config:
          'dis-uuid':
            toNodeId: 'dat-uuid'

      metadata =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'dis-uuid'

      @sut = new EngineDebug metadata
      @sut.write envelope
      @sut.on 'data', (@result) => done()

    it 'should have the envelope waiting in the stream', ->
      expect(@result).to.deep.equal
        devices: ['*']
        topic: 'debug'
        payload:
          node: 'dat-uuid'        
          msg: some: 'data'
