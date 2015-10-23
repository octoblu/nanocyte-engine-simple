NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'
TestStream = require '../helpers/test-stream'

describe 'NanocyteNodeWrapper', ->
  beforeEach ->

    @engineToNanocyteStream = new TestStream
    @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

    @christacheioStream = new TestStream
    @ChristacheioStream = sinon.stub().returns @christacheioStream

    @nanocyteStream = new TestStream
    @NanocyteClass = sinon.stub().returns @nanocyteStream

    @nanocyteToEngineStream = new TestStream
    @NanocyteToEngineStream = sinon.stub().returns @nanocyteToEngineStream

    @dependencies =
      EngineToNanocyteStream: @EngineToNanocyteStream
      ChristacheioStream: @ChristacheioStream
      NanocyteToEngineStream: @NanocyteToEngineStream

    @sut = NanocyteNodeWrapper

  it 'should exist', ->
    expect(NanocyteNodeWrapper).to.exist

  it 'should have a wrap function', ->
    expect(NanocyteNodeWrapper.wrap).to.be.a 'function'

  describe '->wrap', ->
    describe 'when called with a nanocyte class', ->
      beforeEach ->
        @WrappedNanocyteClass = @sut.wrap @NanocyteClass

      it 'should return a class', ->
        expect(@WrappedNanocyteClass).to.be.a 'function'

      describe 'when the WrappedNanocyteClass is instantiated', ->
        beforeEach ->
          @wrappedNanocyte = new @WrappedNanocyteClass @dependencies

        describe 'when messaged to with a nanocyte envelope', ->
          beforeEach ->
            @envelope =
              metadata:
                toNodeId: 'node-id'
                flowId: 'flow-id'
                instanceId: 'instanceId'
              message:
                hi: true

            @engineToNanocyteMessage =
              config: a: 'config'
              data: some: 'data'
              message: its: 'a message'

            @engineToNanocyteStream.onWrite = (envelope, callback) =>
              callback null, @engineToNanocyteMessage


            @christacheioMessage = mustaches: 'are-evil'
            @christacheioStream.onWrite = (envelope, callback) =>
              callback null, @christacheioMessage


            @nanocyteMessage = omg: 'a-message'
            @nanocyteStream.onWrite = (envelope, callback) =>
              callback null, @nanocyteMessage

            @nanocyteToEngineStreamMessage = swarm: true
            @nanocyteToEngineStream.onWrite = (envelope, callback) =>
              callback null, @nanocyteToEngineStreamMessage

            @result = @wrappedNanocyte.message @envelope

          it 'should construct the EngineToNanocyteStream with the flow-id and instance-id', ->
            expect(@EngineToNanocyteStream).to.have.been.calledWithNew
            expect(@EngineToNanocyteStream).to.have.been.calledWith @envelope.metadata

          it 'should write the envelope to the engineToNanocyteStream', ->
            expect(@engineToNanocyteStream.onRead).to.have.been.calledWith @envelope.message

          describe 'when the EngineToNanocyteStream emits a nanocyte envelope', ->
            it 'should construct Christacheio with the flow-id and instance-id', ->
              expect(@ChristacheioStream).to.have.been.calledWithNew
              expect(@ChristacheioStream).to.have.been.calledWith @envelope.metadata

            it 'should send the envelope to the nanocyte', ->
              expect(@christacheioStream.onRead).to.have.been.calledWith @engineToNanocyteMessage

          describe 'when ChristacheioStream emits a nanocyte envelope', ->
            it 'should construct the nanocyte with the flow-id and instance-id', ->
              expect(@NanocyteClass).to.have.been.calledWithNew
              expect(@NanocyteClass).to.have.been.calledWith @envelope.metadata

            it 'should send the envelope to the nanocyte', ->
              expect(@nanocyteStream.onRead).to.have.been.calledWith @christacheioMessage

          describe 'when the the nanocyte emits an envelope', ->
            it 'should construct the NanocyteToEngineStream with the flow-id and instance-id', ->
              expect(@NanocyteToEngineStream).to.have.been.calledWithNew
              expect(@NanocyteToEngineStream).to.have.been.calledWith @envelope.metadata

            it 'should send the envelope to EngineBatch', ->
              expect(@nanocyteToEngineStream.onRead).to.have.been.calledWith @nanocyteMessage

          describe 'when nanocyteToEngineStream emits a message', ->
            beforeEach (done) ->
              @result.on 'data', (@data) => done()

            it 'should emit the message on the returned stream', ->
              expect(@data).to.deep.equal @nanocyteToEngineStreamMessage
