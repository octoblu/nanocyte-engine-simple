EngineDebug = require '../../src/models/engine-debug'
{PassThrough} = require 'stream'

describe 'EngineDebug', ->
  it 'should exist', ->
    expect(EngineDebug).to.exist

  describe 'when constructed', ->
    beforeEach ->
      @sut = new EngineDebug

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

      @sut = new EngineDebug
      @envelopeStream = new PassThrough objectMode: true
      @envelopeStream.pipe @sut
      @envelopeStream.write envelope, done

    it 'should have the envelope waiting in the stream', ->
      expect(@sut.read()).to.deep.equal
        flowId:     'flow-id'
        instanceId: 'instance-id'
        toNodeId:   'engine-output'
        message:
          devices: ['*']
          topic: 'debug'
          payload:
            node: 'dat-uuid'
            msg:
              payload:
                some: 'data'
