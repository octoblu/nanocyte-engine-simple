EngineBatch = require '../../src/models/engine-batch'
_ = require 'lodash'

describe 'EngineBatch', ->
  beforeEach ->
    delete EngineBatch.batches

  describe 'when we write to it', ->
    beforeEach (done) ->
      @sut = new EngineBatch
      @sut.write
        flowId: 'flow-id'
        instanceId: 'instance-id'
        fromNodeId: 'from-node-id'
        toNodeId: 'to-node-id'
        message:
          complications: 'its complicated'
      , done

    describe 'when the stream ends', ->
      beforeEach (done) ->
        @sut.on 'data', (@envelope) =>
        @sut.on 'end', done

      it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
        expect(@envelope).to.deep.equal
          flowId: 'flow-id'
          instanceId: 'instance-id'
          toNodeId: 'to-node-id'
          message:
            topic: 'message-batch'
            payload:
              messages: [{ complications: 'its complicated' }]

      describe 'when we write to a new EngineBatch', ->
        beforeEach (done) ->
          @sut = new EngineBatch
          @sut.write
            flowId: 'flow-id'
            instanceId: 'instance-id'
            fromNodeId: 'from-node-id'
            toNodeId: 'to-node-id'
            message:
              roller: 'coaster'
          , done

        describe 'when the stream ends', ->
          beforeEach (done) ->
            @sut.on 'data', (@envelope) =>
            @sut.on 'end', done

          it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
            expect(@envelope).to.deep.equal
              flowId: 'flow-id'
              instanceId: 'instance-id'
              toNodeId: 'to-node-id'
              message:
                topic: 'message-batch'
                payload:
                  messages: [{ roller: 'coaster' }]

    describe 'when we write a second time', ->
      beforeEach (done) ->
        engine2 = new EngineBatch
        engine2.on 'data', (@engine2Data) =>
        engine2.on 'end', done
        engine2.write
          flowId: 'flow-id'
          instanceId: 'instance-id'
          fromNodeId: 'from-node-id'
          toNodeId: 'to-node-id'
          message:
            sabotage: "Why aren't you all listening - it's sabotage!"

      describe 'when the stream ends', ->
        beforeEach (done) ->
          @sut.on 'data', (@envelope) =>
          @sut.on 'end', done

        it 'should not emit anything from engine2', ->
          expect(@engine2Data).not.to.exist

        it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
          expect(@envelope).to.deep.equal
            flowId: 'flow-id'
            instanceId: 'instance-id'
            toNodeId: 'to-node-id'
            message:
              topic: 'message-batch'
              payload:
                messages: [
                  { complications: 'its complicated' }
                  {sabotage: "Why aren't you all listening - it's sabotage!"}
                ]
