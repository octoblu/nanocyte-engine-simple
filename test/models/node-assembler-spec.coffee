_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'
{Transform, PassThrough, Writable, Readable} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler-spec')

xdescribe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      class StreamTester extends Transform
        constructor: () ->
          super objectMode: true
          @onWrite = sinon.stub()
          @onRead = sinon.stub()

        _transform: (envelope, enc) =>
          @onRead envelope
          @onWrite envelope, (error, newEnvelope) =>
            @push newEnvelope



      @engineToNanocyteStream = new StreamTester
      @EngineToNanocyteStream = sinon.stub().returns @engineToNanocyteStream

      @selectiveCollect = new StreamTester
      @SelectiveCollect = sinon.stub().returns @selectiveCollect

      @triggerNode = new StreamTester
      @TriggerNode = sinon.stub().returns @triggerNode

      @engineData = new StreamTester
      @EngineData = sinon.stub().returns @engineData

      @engineDebug = new StreamTester
      @EngineDebug = sinon.stub().returns @engineDebug

      @datastoreCheckKeyStream = new StreamTester
      @DatastoreCheckKeyStream = sinon.stub().returns @datastoreCheckKeyStream

      class ComponentLoader
        getComponentMap: =>
          {
            'nanocyte-component-pass-through': PassThrough
            'nanocyte-component-selective-collect': @SelectiveCollect
            'nanocyte-component-trigger': @TriggerNode
          }

      @sut = new NodeAssembler {},
        ComponentLoader: ComponentLoader
        EngineToNanocyteStream: @EngineToNanocyteStream
        EngineData: @EngineData
        EngineDebug: @EngineDebug
        DatastoreCheckKeyStream: @DatastoreCheckKeyStream

      @nodes = @sut.assembleNodes()

    describe 'engine-data', ->
      beforeEach ->
        @engineDataNode = @nodes['engine-data']

      it 'should have an onEnvelope function', ->
        expect(@engineDataNode.onEnvelope).to.be.a 'function'


      describe 'when onEnvelope is called', ->
        beforeEach ->
          @engineDataNode.onEnvelope
            metadata:
              flowId: 'flow-id'
              instanceId: 'instance-id'
              toNodeId: 'engine-output'

            message: 'hi'

        it 'should create a new NanocyteEngineStream with the metadata', ->
          expect(@EngineToNanocyteStream).to.have.been.calledWithNew
          expect(@EngineToNanocyteStream).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        it 'should create a new EngineData with the metadata', ->
          expect(@EngineData).to.have.been.calledWithNew
          expect(@EngineData).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        describe 'when EngineToNanocyteStream emits an envelope', ->
          beforeEach ->
            @envelope =
              config:
                hi: true
              data:
                hello: false
              message:
                goodbye: 'maybe'

            @engineToNanocyteStream.onWrite.yield null, @envelope


          it 'should write the data to the EngineData instance', ->
            expect(@engineData.onRead).to.have.been.calledWith @envelope

    describe 'engine-debug', ->
      beforeEach ->
        @engineDebugNode = @nodes['engine-debug']

      it 'should have an onEnvelope function', ->
        expect(@engineDebugNode.onEnvelope).to.be.a 'function'

      describe 'when onEnvelope is called', ->
        beforeEach ->
          @engineDebugNode.onEnvelope
              metadata:
                flowId: 'flow-id'
                instanceId: 'instance-id'
                toNodeId: 'engine-debug'

              message: 'hi'

        it 'should create a new EngineData with the metadata', ->
          expect(@EngineDebug).to.have.been.calledWithNew
          expect(@EngineDebug).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-debug'

        describe 'when EngineToNanocyteStream emits an envelope', ->
          beforeEach ->
            @envelope =
              config:
                hi: true
              data:
                hello: false
              message:
                goodbye: 'maybe'

            @engineToNanocyteStream.onWrite.yield null, @envelope


          it 'should write the data to the datastoreCheckKeyStream instance', ->
            expect(@datastoreCheckKeyStream.onRead).to.have.been.calledWith @envelope

          describe 'when datastoreCheckKeyStream emits an envelope', ->
            beforeEach ->
              @datastoreCheckKeyStream.onWrite.yield null,
                config: 'some-config'
                data: 'some-data'

            it 'should write the data to the EngineDebug instance', ->
              expect(@engineDebug.onRead).to.have.been.calledWith
                config: 'some-config'
                data: 'some-data'

            describe 'when engineDebug emits an envelope', ->
              beforeEach ->
                @engineDebugOnWrite.yield null,
                  flowId: 'flow-id'
                  instanceId: 'instance-id'
                  toNodeId: 'engine-output'
                  message:
                    devices: ['*']
                    topic: 'pulse'
                    payload: 'some-data'

              it 'should pass the envelope on to datastoreGetStream2', ->
                expect(@datastoreGetStreamOnWrite2).to.have.been.calledWith
                  flowId: 'flow-id'
                  instanceId: 'instance-id'
                  toNodeId: 'engine-output'
                  message:
                    devices: ['*']
                    topic: 'pulse'
                    payload: 'some-data'

              describe 'when datastoreGetStream2 emits an envelope', ->
                beforeEach ->
                  @datastoreGetStreamOnWrite2.yield null,
                    config: 'output-config'
                    message:
                      devices: ['*']
                      topic: 'pulse'
                      payload: 'some-data'

                it 'should write the data to the EngineOutput instance', ->
                  expect(@engineOutput.read()).to.deep.equal
                    config: 'output-config'
                    message:
                      devices: ['*']
                      topic: 'pulse'
                      payload: 'some-data'

    describe 'engine-output', ->
      beforeEach ->
        @engineOutputNode = @nodes['engine-output']

      it 'should have an onEnvelope function', ->
        expect(@engineOutputNode.onEnvelope).to.be.a 'function'

      describe 'when onEnvelope is called', ->
        beforeEach ->
          @engineOutputNode.onEnvelope
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        it 'should pass the envelope on to datastoreGetStream1', ->
          expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        describe 'when datastoreGetStream1 emits an envelope', ->
          beforeEach (done) ->
            @engineOutput.on 'readable', done
            @datastoreGetStreamOnWrite1.yield null,
              config: 'some-config'
              data: 'some-data'

          it 'should write the data to the EngineOutput instance', ->
            expect(@engineOutput.read()).to.deep.equal
              config: 'some-config'
              data: 'some-data'

    describe 'engine-pulse', ->
      beforeEach ->
        @enginePulseNode = @nodes['engine-pulse']

      it 'should have an onEnvelope function', ->
        expect(@enginePulseNode.onEnvelope).to.be.a 'function'

      describe 'when onEnvelope is called', ->
        beforeEach ->
          @enginePulseNode.onEnvelope
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        it 'should pass the envelope on to datastoreGetStreamOnWrite1', ->
          expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        describe 'when datastoreGetStream1 emits an envelope', ->
          beforeEach ->
            @datastoreGetStreamOnWrite1.yield null,
              flowId: 'flow-id'
              instanceId: 'instance-id'
              toNodeId: 'engine-output'

          it 'should pass the envelope on to datastoreCheckKeyStream1', ->
            expect(@datastoreCheckKeyStreamOnWrite).to.have.been.calledWith
              flowId: 'flow-id'
              instanceId: 'instance-id'
              toNodeId: 'engine-output'

          describe 'when datastoreCheckKeyStream1 emits an envelope', ->
            beforeEach ->
              @datastoreCheckKeyStreamOnWrite.yield null,
                config: 'some-config'
                data: 'some-data'

            it 'should write the data to the EnginePulse instance', ->
              expect(@enginePulseOnWrite).to.have.been.calledWith
                config: 'some-config'
                data: 'some-data'

            describe 'when enginePulse emits an envelope', ->
              beforeEach ->
                @enginePulseOnWrite.yield null,
                  flowId: 'flow-id'
                  instanceId: 'instance-id'
                  toNodeId: 'engine-output'
                  message:
                    devices: ['*']
                    topic: 'pulse'
                    payload: 'some-data'

              it 'should pass the envelope on to datastoreGetStream2', ->
                expect(@datastoreGetStreamOnWrite2).to.have.been.calledWith
                  flowId: 'flow-id'
                  instanceId: 'instance-id'
                  toNodeId: 'engine-output'
                  message:
                    devices: ['*']
                    topic: 'pulse'
                    payload: 'some-data'

              describe 'when datastoreGetStream2 emits an envelope', ->
                beforeEach ->
                  @datastoreGetStreamOnWrite2.yield null,
                    config: 'output-config'
                    message:
                      devices: ['*']
                      topic: 'pulse'
                      payload: 'some-data'

                it 'should write the data to the EngineOutput instance', ->
                  expect(@engineOutput.read()).to.deep.equal
                    config: 'output-config'
                    message:
                      devices: ['*']
                      topic: 'pulse'
                      payload: 'some-data'

    describe 'nanocyte-component-pass-through', ->
      describe "when the DatastoreGetStream yields an object with a config", ->
        beforeEach ->
          @datastoreGetStreamOnWrite1.yields null, config: 5
          @nanocyteOnWriteMessage.yields null, something: 'yielded'

        describe "nanocyte-component-pass-through's onEnvelope is called", ->
          beforeEach (done) ->
            envelope   = message: 'in a bottle'
            @passThrough = @nodes['nanocyte-component-pass-through']
            @passThrough.onEnvelope envelope, (@error, @result) => done()

          it 'should construct an NanocyteNodeWrapper with an PassThrough class', ->
            expect(@NanocyteNodeWrapper).to.have.been.calledWithNew
            expect(@NanocyteNodeWrapper).to.have.been.calledWith nodeClass: @PassThrough

          it 'should write the envelope to a DatastoreGetStream', ->
            expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith message: 'in a bottle'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@nanocyteOnWriteMessage).to.have.been.calledWith config: 5

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal something: 'yielded'

      describe "when the DatastoreGetStream yields an object with a different config", ->
        beforeEach ->
          @datastoreGetStreamOnWrite1.yields null, config: 'tree'
          @nanocyteOnWriteMessage.yields null, somethingElse: 'still-yielded'

        describe "nanocyte-component-pass-through's onEnvelope is called with an envelope", ->
          beforeEach (done) ->
            envelope   = message: 'message'
            @passThrough = @nodes['nanocyte-component-pass-through']
            @passThrough.onEnvelope envelope, (@error, @result) => done()

          it 'should call DatastoreGetStream.onEnvelope with the envelope', ->
            expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith message: 'message'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@nanocyteOnWriteMessage).to.have.been.calledWith config: 'tree'

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal somethingElse: 'still-yielded'
