_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'
{Readable}  = require 'stream'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @datastoreInStreamOnEnvelope = datastoreInStreamOnEnvelope = sinon.stub()

      class DatastoreInStream extends Readable
        constructor: ({envelope: @envelope}) ->
          super objectMode: true

        _read: =>
          datastoreInStreamOnEnvelope @envelope, (error, newEnvelope) =>
            @push newEnvelope
            @push null

      @nanocyteNodeWrapperOnEnvelope = nanocyteNodeWrapperOnEnvelope = sinon.stub()
      class NanocyteNodeWrapper
        constructor: ({nodeClass: @nodeClass}) ->
        onEnvelope: nanocyteNodeWrapperOnEnvelope

      @NanocyteNodeWrapper = sinon.spy NanocyteNodeWrapper

      @OutputNodeWrapper = sinon.spy =>
        onEnvelope: ->

      @DebugNode = ->
        onMessage: ->

      @OutputNode = ->
        onMessage: ->

      @sut = new NodeAssembler {},
        DatastoreInStream: DatastoreInStream
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
        'meshblu-output'
      ]

    it 'should return wrappers for each node', ->
      _.each @nodes, (node) =>
        expect(node.onEnvelope).to.exist

    it 'should construct an OutputNodeWrapper with an OutputNode class', ->
      expect(@OutputNodeWrapper).to.have.been.calledWithNew
      expect(@OutputNodeWrapper).to.have.been.calledWith nodeClass: @OutputNode

    describe "when the DatastoreInStream yields an object with a config", ->
      beforeEach ->
        @datastoreInStreamOnEnvelope.yields null, config: 5
        @nanocyteNodeWrapperOnEnvelope.yields null, something: 'yielded'

      describe "nanocyte-node-debug node's onEnvelope is called", ->
        beforeEach (done) ->
          envelope   = message: 'in a bottle'
          @debugNode = @nodes['nanocyte-node-debug']
          @debugNode.onEnvelope envelope, (@error, @result) => done()

        it 'should construct an NanocyteNodeWrapper with an OutputNode class', ->
          expect(@NanocyteNodeWrapper).to.have.been.calledWithNew
          expect(@NanocyteNodeWrapper).to.have.been.calledWith nodeClass: @DebugNode

        it 'should call DatastoreInStream.onEnvelope with the envelope', ->
          expect(@datastoreInStreamOnEnvelope).to.have.been.calledWith message: 'in a bottle'

        it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
          expect(@nanocyteNodeWrapperOnEnvelope).to.have.been.calledWith config: 5

        it "should have called the callback with whatever debug yielded", ->
          expect(@result).to.deep.equal something: 'yielded'

    describe "when the DatastoreInStream yields an object with a different config", ->
      beforeEach ->
        @datastoreInStreamOnEnvelope.yields null, config: 'tree'
        @nanocyteNodeWrapperOnEnvelope.yields null, somethingElse: 'still-yielded'

      describe "nanocyte-node-debug node's onEnvelope is called with an envelope", ->
        beforeEach (done) ->
          envelope   = message: 'message'
          @debugNode = @nodes['nanocyte-node-debug']
          @debugNode.onEnvelope envelope, (@error, @result) => done()

        it 'should call DatastoreInStream.onEnvelope with the envelope', ->
          expect(@datastoreInStreamOnEnvelope).to.have.been.calledWith message: 'message'

        it "should call NanocyteNodeWrapper.onEnvelope with the config of the debug node", ->
          expect(@nanocyteNodeWrapperOnEnvelope).to.have.been.calledWith config: 'tree'

        it "should have called the callback with whatever debug yielded", ->
          expect(@result).to.deep.equal somethingElse: 'still-yielded'
