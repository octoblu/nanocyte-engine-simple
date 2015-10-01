_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'
stream  = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler-spec')

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @datastoreGetStreamOnWrite1 = sinon.stub()
      @datastoreGetStreamOnWrite2 = sinon.stub()
      datastoreGetStreamOnWrites = [@datastoreGetStreamOnWrite1, @datastoreGetStreamOnWrite2]
      class DatastoreGetStream extends stream.Transform
        constructor: ->
          super objectMode: true
          @datastoreGetStreamOnWrite = datastoreGetStreamOnWrites.shift()

        _transform: (envelope, enc, next)=>
          debug '_transform'
          @datastoreGetStreamOnWrite envelope, (error, newEnvelope) =>
            @push newEnvelope

      @nanocyteOnWriteMessage = nanocyteOnWriteMessage = sinon.stub()
      class NanocyteNodeWrapper extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: (envelope, enc, next) =>
          nanocyteOnWriteMessage envelope, (error, nextEnvelope) =>
            @push nextEnvelope
      @NanocyteNodeWrapper = sinon.spy NanocyteNodeWrapper

      @engineDebugOnWrite = engineDebugOnWrite = sinon.stub()
      class EngineDebug extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: (envelope, enc, next) =>
          engineDebugOnWrite envelope, (error, nextEnvelope) =>
            @push nextEnvelope
            @push null

      @enginePulseOnWrite = enginePulseOnWrite = sinon.stub()
      class EnginePulse extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: (envelope, enc, next) =>
          enginePulseOnWrite envelope, (error, nextEnvelope) =>
            @push nextEnvelope
            @push null

      @engineOutput = new stream.PassThrough objectMode: true
      EngineOutput = => @engineOutput

      @engineData = new stream.PassThrough objectMode: true
      EngineData = => @engineData

      @PassThrough = sinon.spy()
      @SelectiveCollect = sinon.spy()
      @TriggerNode = sinon.spy()

      @sut = new NodeAssembler {},
        DatastoreGetStream: DatastoreGetStream
        NanocyteNodeWrapper: @NanocyteNodeWrapper
        EngineData: EngineData
        EngineDebug: EngineDebug
        EngineOutput: EngineOutput
        EnginePulse: EnginePulse
        PassThrough: @PassThrough
        SelectiveCollect: @SelectiveCollect
        TriggerNode: @TriggerNode
        OutputNode: @OutputNode

      @nodes = @sut.assembleNodes()

    it 'should return something', ->
      expect(@nodes).not.to.be.empty

    it 'should return an object with keys for each node', ->
      expect(@nodes).to.have.all.keys [
        'engine-data'
        'engine-debug'
        'engine-output'
        'engine-pulse'
        'nanocyte-component-body-parser'
        'nanocyte-component-broadcast'
        'nanocyte-component-change'
        'nanocyte-component-clear-data'
        'nanocyte-component-clear-if-length-greater-than-max-else-pass-through'
        'nanocyte-component-collect'
        'nanocyte-component-contains-all-keys'
        'nanocyte-component-demultiplex'
        'nanocyte-component-equal'
        'nanocyte-component-http-formatter'
        'nanocyte-component-http-request'
        'nanocyte-component-flow-metric-start'
        'nanocyte-component-flow-metric-stop'
        'nanocyte-component-get-key-from-data'
        'nanocyte-component-greater-than'
        'nanocyte-component-interval-register'
        'nanocyte-component-interval-unregister'
        'nanocyte-component-less-than'
        'nanocyte-component-map-message-to-key'
        'nanocyte-component-math'
        'nanocyte-component-meshblu-output'
        'nanocyte-component-not-equal'
        'nanocyte-component-null'
        'nanocyte-component-octoblu-channel-request-formatter'
        'nanocyte-component-pass-through'
        'nanocyte-component-pass-through-if-length-greater-than-min'
        'nanocyte-component-pluck'
        'nanocyte-component-range'
        'nanocyte-component-sample'
        'nanocyte-component-selective-collect'
        'nanocyte-component-trigger'
      ]

    describe 'engine-data', ->
      beforeEach ->
        @engineDataNode = @nodes['engine-data']

      it 'should have an onEnvelope function', ->
        expect(@engineDataNode.onEnvelope).to.be.a 'function'

      describe 'when onEnvelope is called', ->
        beforeEach ->
          @engineDataNode.onEnvelope
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
            @engineData.on 'readable', done
            @datastoreGetStreamOnWrite1.yield null,
              config: 'some-config'
              data: 'some-data'

          it 'should write the data to the EngineData instance', ->
            expect(@engineData.read()).to.deep.equal
              config: 'some-config'
              data: 'some-data'

    describe 'engine-debug', ->
      beforeEach ->
        @PassThrough = @nodes['engine-debug']

      it 'should have an onEnvelope function', ->
        expect(@PassThrough.onEnvelope).to.be.a 'function'

      describe 'when onEnvelope is called', ->
        beforeEach ->
          @PassThrough.onEnvelope
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-debug'

        it 'should pass the envelope on to datastoreGetStream', ->
          expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-debug'

        describe 'when datastoreGetStream1 emits an envelope', ->
          beforeEach ->
            @datastoreGetStreamOnWrite1.yield null,
              config: 'some-config'
              data: 'some-data'

          it 'should write the data to the EngineDebug instance', ->
            expect(@engineDebugOnWrite).to.have.been.calledWith
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

        it 'should pass the envelope on to datastoreGetStream1', ->
          expect(@datastoreGetStreamOnWrite1).to.have.been.calledWith
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'engine-output'

        describe 'when datastoreGetStream1 emits an envelope', ->
          beforeEach ->
            @datastoreGetStreamOnWrite1.yield null,
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
