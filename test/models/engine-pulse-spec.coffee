EnginePulse = require '../../src/models/engine-pulse'
{PassThrough} = require 'stream'

describe 'EnginePulse', ->
  it 'should exist', ->
    expect(EnginePulse).to.exist

  describe 'when constructed', ->
    beforeEach ->
      @sut = new EnginePulse

    it 'should exist', ->
      expect(@sut).to.exist

  describe 'when we pipe the envelopeStream and pipe it to the sut', ->
    beforeEach (done) ->
      envelope =
        message:
          some: 'data'
        config:
          'dis-uuid': nodeId: 'dat-uuid'
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'dis-uuid'

      @sut = new EnginePulse
      @envelopeStream = new PassThrough objectMode: true
      @envelopeStream.pipe @sut
      @envelopeStream.write envelope, done

    it 'should have the message waiting in the stream', ->
      expect(@sut.read()).to.deep.equal
        flowId:     'flow-id'
        instanceId: 'instance-id'
        toNodeId:   'engine-output'
        message:
          devices: ['*']
          topic: 'pulse'
          payload:
            node: 'dat-uuid'
