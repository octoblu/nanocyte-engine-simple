EngineDataNode = require '../../src/models/engine-data-node'
TestStream = require '../helpers/test-stream'

describe 'EngineDataNode', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @engineDataStream = new TestStream
    @EngineData = sinon.stub().returns @engineDataStream

    @nanocyteToEngineStream = new TestStream
    @NanocyteToEngineStream = sinon.stub().returns @nanocyteToEngineStream

    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream
      EngineData: @EngineData
      NanocyteToEngineStream: @NanocyteToEngineStream

  it 'should exist', ->
    expect(EngineDataNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
      @envelope =
        metadata:
          toNodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EngineDataNode @dependencies

      @engineToNanocyteMessage =
        config: a: 'config'
        data: some: 'data'
        message: its: 'a message'

      @engineToNanocyteStream.onWrite = (envelope, callback) =>
        callback null, @engineToNanocyteMessage

      @engineDataMessage = something: 'else'

      @engineDataStream.onWrite = (envelope, callback) =>
        callback null, @engineDataMessage

      @nanocyteToEngineStreamMessage =
        swarm: true
      @nanocyteToEngineStream.onWrite = (envelope, callback) =>
        callback null, @nanocyteToEngineStreamMessage

      @result = @sut.message @envelope

    it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
      expect(@EngineToNanocyteStream).to.have.been.calledWithNew
      expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata

    it 'should write the envelope to the engineToNanocyteStream', ->
      expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @envelope.message

    describe 'when the EngineToNanocyteStream emits a nanocyte envelope', ->
      it 'should construct the EngineData with the flow-id and instance-id', ->
        expect(@EngineData).to.have.been.calledWithNew
        expect(@EngineData).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineData', ->
        expect(@engineDataStream.onRead).to.have.been.calledWith @engineToNanocyteMessage

    describe 'when the EngineData emits an envelope', ->
      it 'should construct the NanocyteToEngineStream with the flow-id and instance-id', ->
        expect(@NanocyteToEngineStream).to.have.been.calledWithNew
        expect(@NanocyteToEngineStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineBatch', ->
        expect(@nanocyteToEngineStream.onRead).to.have.been.calledWith @engineDataMessage

    describe 'when nanocyteToEngineStream emits a message', ->
      beforeEach (done) ->
        @result.on 'data', (@data) => done()

      it 'should emit the message on the returned stream', ->
        expect(@data).to.deep.equal @nanocyteToEngineStreamMessage
