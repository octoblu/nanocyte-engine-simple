EngineDebugNode = require '../../src/models/engine-debug-node'
TestStream = require '../helpers/test-stream'

describe 'EngineDebugNode', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @datastoreCheckKeyStream = new TestStream
    @DatastoreCheckKeyStream = sinon.stub().returns @datastoreCheckKeyStream

    @engineDebugStream = new TestStream
    @EngineDebug = sinon.stub().returns @engineDebugStream

    @nanocyteToEngineStream = new TestStream
    @NanocyteToEngineStream = sinon.stub().returns @nanocyteToEngineStream

    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream
      NanocyteToEngineStream: @NanocyteToEngineStream
      DatastoreCheckKeyStream: @DatastoreCheckKeyStream
      EngineDebug: @EngineDebug

  it 'should exist', ->
    expect(EngineDebugNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
      @envelope =
        metadata:
          toNodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EngineDebugNode @dependencies

      @datastoreCheckKeyMessage =
        is_excited: ['erik', 'aaron']

      @datastoreCheckKeyStream.onWrite = (envelope, callback) =>
        callback null, @datastoreCheckKeyMessage

      @engineToNanocyteMessage =
        config: a: 'config'
        data: some: 'data'
        message: its: 'a message'

      @engineToNanocyteStream.onWrite = (envelope, callback) =>
        callback null, @engineToNanocyteMessage


      @engineDebugMessage = something: 'else'

      @engineDebugStream.onWrite = (envelope, callback) =>
        callback null, @engineDebugMessage

      @result = @sut.message @envelope

    it 'should return the engineToNanocyteStream', ->
      expect(@result).to.equal @nanocyteToEngineStream

    it 'should construct the DatastoreCheckKeyStream with the flow-id and instance-id', ->
      expect(@DatastoreCheckKeyStream).to.have.been.calledWithNew
      expect(@DatastoreCheckKeyStream).to.have.been.calledWith @envelope.metadata

    it 'should write the envelope to the engineToNanocyteStream', ->
      expect(@datastoreCheckKeyStream.onRead).to.have.been.calledWith @envelope.message

    # it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
    #   expect(@EngineToNanocyteStream).to.have.been.calledWithNew
    #   expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata
    #
    # it 'should write the envelope to the engineToNanocyteStream', ->
    #   expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @envelope.message

    describe 'when the DatastoreCheckKeyStream emits a nanocyte envelope', ->

      it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
        expect(@EngineToNanocyteStream).to.have.been.calledWithNew
        expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineToNanocyteStream', ->
        expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @datastoreCheckKeyMessage


    describe 'when the EngineToNanocyteStream emits a nanocyte envelope', ->
      it 'should construct the EngineDebug with the flow-id and instance-id', ->
        expect(@EngineDebug).to.have.been.calledWithNew
        expect(@EngineDebug).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineDebug', ->
        expect(@engineDebugStream.onRead).to.have.been.calledWith @engineToNanocyteMessage

    describe 'when the EngineDebug emits an envelope', ->
      it 'should construct the NanocyteToEngineStream with the flow-id and instance-id', ->
        expect(@NanocyteToEngineStream).to.have.been.calledWithNew
        expect(@NanocyteToEngineStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineToNanocyteStream', ->
        expect(@nanocyteToEngineStream.onRead).to.have.been.calledWith @engineDebugMessage
