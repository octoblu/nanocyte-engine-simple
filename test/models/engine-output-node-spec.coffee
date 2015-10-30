EngineOutputNode = require '../../src/models/engine-output-node'
TestStream = require '../helpers/test-stream'

describe 'EngineOutputNode', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @engineOutputStream = new TestStream
    @EngineOutput = sinon.stub().returns @engineOutputStream

    @engineOutputThrottle = new TestStream
    @EngineOutputThrottle = sinon.stub().returns @engineOutputThrottle

    @nanocyteToEngineStream = new TestStream
    @NanocyteToEngineStream = sinon.stub().returns @nanocyteToEngineStream

    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream
      EngineOutput: @EngineOutput
      EngineOutputThrottle: @EngineOutputThrottle
      NanocyteToEngineStream: @NanocyteToEngineStream

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

      @engineToNanocyteMessage =
        config: a: 'config'
        data: some: 'data'
        message: its: 'a message'

      @engineToNanocyteStream.onWrite = (envelope, callback) =>
        callback null, @engineToNanocyteMessage

      @engineOutputMessage = something: 'else'

      @engineOutputStream.onWrite = (envelope, callback) =>
        callback null, @engineOutputMessage

      @engineOutputThrottleMessage =
        a: 'batch'
        of: 'cookies'

      @engineOutputThrottle.onWrite = (envelope, callback) =>
        callback null, @engineOutputThrottleMessage

      @nanocyteToEngineStreamMessage =
        swarm: true
      @nanocyteToEngineStream.onWrite = (envelope, callback) =>
        callback null, @nanocyteToEngineStreamMessage

      @result = @sut.message @envelope

    describe 'when the engineToNanocyteStream emits an envelope', ->

      it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
        expect(@EngineToNanocyteStream).to.have.been.calledWithNew
        expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata


    describe 'when the EngineToNanocyteStream emits a nanocyte envelope', ->
      it 'should construct the EngineOutput with the flow-id and instance-id', ->
        expect(@EngineOutputThrottle).to.have.been.calledWithNew
        expect(@EngineOutputThrottle).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineOutputThrottle', ->
        expect(@engineOutputThrottle.onRead).to.have.been.calledWith @engineToNanocyteMessage

    describe 'when the EngineOutputThrottle emits an envelope', ->
      it 'should construct the EngineOutputThrottle with the flow-id and instance-id', ->
        expect(@EngineOutput).to.have.been.calledWithNew
        expect(@EngineOutput).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to EngineOutput', ->
        expect(@engineOutputStream.onRead).to.have.been.calledWith @engineOutputThrottleMessage

    describe 'when the EngineOutput emits an envelope', ->
      it 'should construct the NanocyteToEngineStream with the flow-id and instance-id', ->
        expect(@NanocyteToEngineStream).to.have.been.calledWithNew
        expect(@NanocyteToEngineStream).to.have.been.calledWith @envelope.metadata

      it 'should send the envelope to the nanocyteToEngineStream', ->
        expect(@nanocyteToEngineStream.onRead).to.have.been.calledWith @engineOutputMessage

    describe 'when nanocyteToEngineStream emits a message', ->
      beforeEach (done) ->
        @result.on 'data', (@data) => done()

      it 'should emit the message on the returned stream', ->
        expect(@data).to.deep.equal @nanocyteToEngineStreamMessage
