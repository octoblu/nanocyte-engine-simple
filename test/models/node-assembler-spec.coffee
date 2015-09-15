_ = require 'lodash'
NodeAssembler = require '../../src/models/node-assembler'
stream  = require 'stream'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @datastoreGetStreamOnEnvelope = datastoreGetStreamOnEnvelope = sinon.stub()

      class DatastoreGetStream extends stream.Readable
        constructor: ({envelope: @envelope}) ->
          super objectMode: true

        _read: =>
          datastoreGetStreamOnEnvelope @envelope, (error, newEnvelope) =>
            @push newEnvelope
            @push null

      @debugOnWriteMessage = debugOnWriteMessage = sinon.stub()

      class DebugNode extends stream.Writable
        constructor: ->
          super objectMode: true
          @messageOutputStream = new stream.PassThrough objectMode: true

        _write: (envelope, enc, next) =>
          debugOnWriteMessage envelope, (error, nextEnvelope) =>
            @messageOutputStream.push nextEnvelope
            @messageOutputStream.push null
            next()

      @OutputNodeWrapper = sinon.spy =>
        onEnvelope: ->

      @DebugNode = DebugNode

      @OutputNode = ->
        onMessage: ->

      @sut = new NodeAssembler {},
        DatastoreGetStream: DatastoreGetStream
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

    it 'should construct an OutputNodeWrapper with an OutputNode class', ->
      expect(@OutputNodeWrapper).to.have.been.calledWithNew
      expect(@OutputNodeWrapper).to.have.been.calledWith nodeClass: @OutputNode

    describe "when the DatastoreGetStream yields an object with a config", ->
      beforeEach ->
        @datastoreGetStreamOnEnvelope.yields null, config: 5
        @debugOnWriteMessage.yields null, something: 'yielded'

      describe "nanocyte-node-debug node's onEnvelope is called", ->
        beforeEach (done) ->
          envelope   = message: 'in a bottle'
          @debugNode = @nodes['nanocyte-node-debug']
          @debugNode.onEnvelope envelope, (@error, @result) => done()

        it 'should construct a DebugNode', ->
          expect(@debugNode.onEnvelope).to.exist

        it 'should call DatastoreGetStream.onEnvelope with the envelope', ->
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
