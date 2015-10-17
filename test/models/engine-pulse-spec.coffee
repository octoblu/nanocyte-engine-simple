EnginePulse = require '../../src/models/engine-pulse'
{PassThrough} = require 'stream'

describe 'EnginePulse', ->
  describe 'when we pipe the envelopeStream and pipe it to the sut', ->
    beforeEach (done) ->
      metadata =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'dis-uuid'

      envelope =
        message:
          some: 'data'
        config:
          'dis-uuid': nodeId: 'dat-uuid'

      @sut = new EnginePulse metadata
      @sut.write envelope
      @sut.on 'data', (@result) => done()

    it 'should have the message waiting in the stream', ->
      expect(@result).to.deep.equal
        devices: ['*']
        topic: 'pulse'
        payload:
          node: 'dat-uuid'
