_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'
stream  = require 'stream'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @datastoreGetStreamOnEnvelope = datastoreGetStreamOnEnvelope = sinon.stub()

      class DatastoreGetStream extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: (envelope, enc, next)=>
          datastoreGetStreamOnEnvelope envelope, (error, newEnvelope) =>
            @push newEnvelope
            @push null

      @debugOnWriteMessage = debugOnWriteMessage = sinon.stub()

      class NanocyteNodeWrapper extends stream.Transform
        constructor: ->
          super objectMode: true

        _transform: (envelope, enc, next) =>
          debugOnWriteMessage envelope, (error, nextEnvelope) =>
            @push nextEnvelope

          next()

      @NanocyteNodeWrapper = sinon.spy NanocyteNodeWrapper

      @OutputNodeWrapper = sinon.spy =>
        onEnvelope: ->

      @DebugNode = sinon.spy()

      @OutputNode = ->
        onMessage: ->

      @sut = new NodeAssembler {},
        DatastoreGetStream: DatastoreGetStream
        NanocyteNodeWrapper: @NanocyteNodeWrapper
        OutputNodeWrapper: @OutputNodeWrapper
        DebugNode: @DebugNode
        OutputNode: @OutputNode

      @nodes = @sut.assembleNodes()


    it 'should return something', ->
      expect(@nodes).not.to.be.empty

    it 'should return an object with keys for each node', ->
      expect(@nodes).to.have.all.keys [
        'nanocyte-node-debug'
        'nanocyte-node-trigger'
        'engine-output'
      ]

    it 'should construct an OutputNodeWrapper with an OutputNode class', ->
      expect(@OutputNodeWrapper).to.have.been.calledWithNew
      expect(@OutputNodeWrapper).to.have.been.calledWith nodeClass: @OutputNode

    describe 'nanocyte-node-debug', ->
      describe "when the DatastoreGetStream yields an object with a config", ->
        beforeEach ->
          @datastoreGetStreamOnEnvelope.yields null, config: 5
          @debugOnWriteMessage.yields null, something: 'yielded'

        describe "nanocyte-node-debug node's onEnvelope is called", ->
          beforeEach (done) ->
            envelope   = message: 'in a bottle'
            @debugNode = @nodes['nanocyte-node-debug']
            @debugNode.onEnvelope envelope, (@error, @result) => done()

          it 'should construct an NanocyteNodeWrapper with an DebugNode class', ->
            expect(@NanocyteNodeWrapper).to.have.been.calledWithNew
            expect(@NanocyteNodeWrapper).to.have.been.calledWith nodeClass: @DebugNode

          it 'should write the envelope to a DatastoreGetStream', ->
            expect(@datastoreGetStreamOnEnvelope).to.have.been.calledWith message: 'in a bottle'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@debugOnWriteMessage).to.have.been.calledWith config: 5

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal something: 'yielded'

      describe "when the DatastoreGetStream yields an object with a different config", ->
        beforeEach ->
          @datastoreGetStreamOnEnvelope.yields null, config: 'tree'
          @debugOnWriteMessage.yields null, somethingElse: 'still-yielded'

        describe "nanocyte-node-debug node's onEnvelope is called with an envelope", ->
          beforeEach (done) ->
            envelope   = message: 'message'
            @debugNode = @nodes['nanocyte-node-debug']
            @debugNode.onEnvelope envelope, (@error, @result) => done()

          it 'should call DatastoreGetStream.onEnvelope with the envelope', ->
            expect(@datastoreGetStreamOnEnvelope).to.have.been.calledWith message: 'message'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@debugOnWriteMessage).to.have.been.calledWith config: 'tree'

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal somethingElse: 'still-yielded'

    describe 'nanocyte-node-trigger', ->
      describe "when the DatastoreGetStream yields an object with a config", ->
        beforeEach ->
          @datastoreGetStreamOnEnvelope.yields null, config: 5
          @debugOnWriteMessage.yields null, something: 'yielded'

        describe "nanocyte-node-trigger node's onEnvelope is called", ->
          beforeEach (done) ->
            envelope   = message: 'in a bottle'
            @debugNode = @nodes['nanocyte-node-trigger']
            @debugNode.onEnvelope envelope, (@error, @result) => done()

          it 'should construct an NanocyteNodeWrapper with an DebugNode class', ->
            expect(@NanocyteNodeWrapper).to.have.been.calledWithNew
            expect(@NanocyteNodeWrapper).to.have.been.calledWith nodeClass: @DebugNode

          it 'should write the envelope to a DatastoreGetStream', ->
            expect(@datastoreGetStreamOnEnvelope).to.have.been.calledWith message: 'in a bottle'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@debugOnWriteMessage).to.have.been.calledWith config: 5

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal something: 'yielded'

      describe "when the DatastoreGetStream yields an object with a different config", ->
        beforeEach ->
          @datastoreGetStreamOnEnvelope.yields null, config: 'tree'
          @debugOnWriteMessage.yields null, somethingElse: 'still-yielded'

        describe "nanocyte-node-trigger node's onEnvelope is called with an envelope", ->
          beforeEach (done) ->
            envelope   = message: 'message'
            @debugNode = @nodes['nanocyte-node-trigger']
            @debugNode.onEnvelope envelope, (@error, @result) => done()

          it 'should call DatastoreGetStream.onEnvelope with the envelope', ->
            expect(@datastoreGetStreamOnEnvelope).to.have.been.calledWith message: 'message'

          it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
            expect(@debugOnWriteMessage).to.have.been.calledWith config: 'tree'

          it "should have called the callback with whatever debug yielded", ->
            expect(@result).to.deep.equal somethingElse: 'still-yielded'
