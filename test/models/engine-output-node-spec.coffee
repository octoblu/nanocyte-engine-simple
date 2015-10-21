EngineOutputNode = require '../../src/models/engine-output-node'
TestStream = require '../helpers/test-stream'

describe 'EngineOutputNode', ->
  beforeEach ->
    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream
    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream

  it 'should exist', ->
    expect(EngineOutputNode).to.exist

  describe 'when messaged to with a nanocyte message', ->
    beforeEach ->
      @envelope =
        metadata:
          nodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EngineOutputNode @dependencies
      @sut.message @envelope

    it 'should write the message to the engineToNanocyteStream', ->
      expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @envelope.message

    it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
      expect(@EngineToNanocyteStream).to.have.been.calledWithNew
      expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata
