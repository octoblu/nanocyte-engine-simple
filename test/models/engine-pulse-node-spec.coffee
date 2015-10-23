EnginePulseNode = require '../../src/models/engine-pulse-node'
TestStream = require '../helpers/test-stream'

describe 'EnginePulseNode', ->
  beforeEach ->

    @datastoreCheckKeyStream = new TestStream
    @DatastoreCheckKeyStream = sinon.stub().returns @datastoreCheckKeyStream

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @enginePulseStream = new TestStream
    @EnginePulse = sinon.stub().returns @enginePulseStream

    @engineBatch = new TestStream
    @EngineBatch = sinon.stub().returns @engineBatch

    @nanocyteToEngineStream = new TestStream
    @NanocyteToEngineStream = sinon.stub().returns @nanocyteToEngineStream

    @dependencies =
      DatastoreCheckKeyStream: @DatastoreCheckKeyStream
      EngineToNanocyteStream: @EngineToNanocyteStream
      EnginePulse: @EnginePulse
      EngineBatch: @EngineBatch
      NanocyteToEngineStream: @NanocyteToEngineStream

  it 'should exist', ->
    expect(EnginePulseNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
      @envelope =
        metadata:
          toNodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EnginePulseNode @dependencies

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


      @enginePulseMessage = something: 'else'

      @enginePulseStream.onWrite = (envelope, callback) =>
        callback null, @enginePulseMessage

      @engineBatchMessage =
        a: 'batch'
        of: 'cookies'

      @engineBatch.onWrite = (envelope, callback) =>
        callback null, @engineBatchMessage

      @nanocyteToEngineStreamMessage =
        swarm: true
      @nanocyteToEngineStream.onWrite = (envelope, callback) =>
        callback null, @nanocyteToEngineStreamMessage

      @result = @sut.message @envelope

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

    describe 'when the DatastoreCheckKeyStream emits an envelope', ->

      it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
        expect(@EngineToNanocyteStream).to.have.been.calledWithNew
        expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineToNanocyteStream', ->
        expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @datastoreCheckKeyMessage


    describe 'when the EngineToNanocyteStream emits a nanocyte envelope', ->
      it 'should construct the EnginePulse with the flow-id and instance-id', ->
        expect(@EnginePulse).to.have.been.calledWithNew
        expect(@EnginePulse).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EnginePulse', ->
        expect(@enginePulseStream.onRead).to.have.been.calledWith @engineToNanocyteMessage

    describe 'when the EnginePulse emits an envelope', ->
      it 'should construct the EngineBatch with the flow-id and instance-id', ->
        expect(@EngineBatch).to.have.been.calledWithNew
        expect(@EngineBatch).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineBatch', ->
        expect(@engineBatch.onRead).to.have.been.calledWith @enginePulseMessage

    describe 'when the EngineBatch emits an envelope', ->
      it 'should construct the NanocyteToEngineStream with the flow-id and instance-id', ->
        expect(@NanocyteToEngineStream).to.have.been.calledWithNew
        expect(@NanocyteToEngineStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to the nanocyteToEngineStream', ->
        expect(@nanocyteToEngineStream.onRead).to.have.been.calledWith @engineBatchMessage

    describe 'when nanocyteToEngineStream emits a message', ->
      beforeEach (done) ->
        @result.on 'data', (@data) => done()

      it 'should emit the message on the returned stream', ->
        expect(@data).to.deep.equal @nanocyteToEngineStreamMessage
