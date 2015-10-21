EngineDebugNode = require '../../src/models/engine-debug-node'
TestStream = require '../helpers/test-stream'

describe 'EngineDebugNode', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @datastoreCheckKeyStream = new TestStream
    @DatastoreCheckKeyStream = sinon.stub().returns @datastoreCheckKeyStream

    @engineDebug = new TestStream
    @EngineDebug = sinon.stub().returns @engineDebug

    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream
      DatastoreCheckKeyStream: @DatastoreCheckKeyStream
      EngineDebug: @EngineDebug

  it 'should exist', ->
    expect(EngineDebugNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
      @envelope =
        metadata:
          nodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EngineDebugNode @dependencies
      @sut.message @envelope

    it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
      expect(@EngineToNanocyteStream).to.have.been.calledWithNew
      expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata

    it 'should write the envelope to the engineToNanocyteStream', ->
      expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @envelope.message
