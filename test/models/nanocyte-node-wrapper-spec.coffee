NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'
stream = require 'stream'

describe 'NanocyteNodeWrapper', ->
  describe 'on write', ->
    beforeEach ->
      @mahNodeOnWrite = mahNodeOnWrite = sinon.stub()

      class MahNode extends stream.Writable
        constructor: ->
          super objectMode: true
          @messageOutStream = new stream.PassThrough objectMode: true

        _write: (envelope, enc, next) =>
          mahNodeOnWrite envelope, (error, nextEnvelope) =>
            @messageOutStream.write nextEnvelope, enc, next

      @sut = new NanocyteNodeWrapper nodeClass: MahNode

    describe 'when an envelope is written to it', ->
      beforeEach (done) ->
        @mahNodeOnWrite.yields null, message: {some: 'message'}
        @sut.write flowId: 5, config: {contains: 'config'}, data: {is: 'data'}, message: {foo: 'bar'}, done

      it 'should call onMessage on MahNode', ->
        expect(@mahNodeOnWrite).to.have.been.calledWith
          config: {contains: 'config'}
          data: {is: 'data'}
          message: {foo: 'bar'}

      it 'should have the output message waiting in the messageOutStream', ->
        expect(@sut.messageOutStream.read()).to.deep.equal
          flowId: 5
          message: {some: 'message'}
