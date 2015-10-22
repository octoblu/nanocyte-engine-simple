EngineOutputNode = require '../../src/models/engine-output-node'
TestStream = require '../helpers/test-stream'

describe 'EngineOutputNode', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @engineOutput = new TestStream
    @EngineOutput = sinon.stub().returns @engineOutput

    @engineBatch = new TestStream
    @EngineBatch = sinon.stub().returns @engineBatch

    @serializerStream = new TestStream
    @SerializerStream = sinon.stub().returns @serializerStream

    @dependencies =
      EngineBatch : @EngineBatch
      SerializerStream: @SerializerStream
      EngineToNanocyteStream: @EngineToNanocyteStream
      EngineOutput: @EngineOutput


  it 'should exist', ->
    expect(EngineOutputNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
      @envelope =
        metadata:
          toNodeId: 'node-id'
          flowId: 'flow-id'
          instanceId: 'instanceId'
        message:
          hi: true

      @sut = new EngineOutputNode @dependencies
      @sut.message @envelope

    it 'should write the envelope to the engineToNanocyteStream', ->
      expect(@engineBatch.onRead).to.have.been.calledWith @envelope.message

    it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
      expect(@EngineBatch).to.have.been.calledWithNew
      expect(@EngineBatch).to.have.been.calledWith @envelope.metadata

    it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
      expect(@EngineToNanocyteStream).to.have.been.calledWithNew
      expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata


    it 'should create a new EngineOutput with the metadata', ->
      expect(@EngineOutput).to.have.been.calledWithNew
      expect(@EngineOutput).to.have.been.calledWith @envelope.metadata

    it 'should create a new SerializerStream', ->
      expect(@SerializerStream).to.have.been.calledWithNew

    describe 'when EngineBatch emits a batched message', ->
      beforeEach ->
        @message =
          topic: 'message-batch'
          payload:
            hi: true

        @engineBatch.onWrite.yield null, @message

      it 'should write the data to the SerializerStream instance', ->
        expect(@serializerStream.onRead).to.have.been.calledWith @message

      describe 'when SerializerStream emits a stringified message', ->
        beforeEach ->
          @message = "whatever"
          @serializerStream.onWrite.yield null, @message

        it 'should write the data to the SerializerStream instance', ->
          expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @message

        describe 'when EngineToNanocyteStream emits a nanocyte message', ->
          beforeEach ->
            @envelope =
              config:
                hi: true
              data:
                hello: false
              message:
                goodbye: 'maybe'

            @engineToNanocyteStream.onWrite.yield null, @envelope

          it 'should write the data to the SerializerStream instance', ->
            expect(@engineOutput.onRead).to.have.been.calledWith @envelope
