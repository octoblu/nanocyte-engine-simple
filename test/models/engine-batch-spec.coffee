EngineBatch = require '../../src/models/engine-batch'
_ = require 'lodash'

describe 'EngineBatch', ->
  beforeEach ->
    delete EngineBatch.batches

  describe 'when we write to it', ->
    beforeEach ->
      metadata =
        flowId: 'flow-id'
        instanceId: 'instance-id'
        nodeId: 'to-node-id'

      @sut = new EngineBatch metadata
      @sut.write complications: 'its complicated'

    describe 'when the stream ends', ->
      beforeEach (done) ->
        @sut.on 'data', (@envelope) => done()

      it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
        expect(@envelope).to.deep.equal
          topic: 'message-batch'
          devices: ['*']
          payload:
            messages: [{ complications: 'its complicated' }]

      describe 'when we write to a new EngineBatch', ->
        beforeEach ->
          metadata =
            flowId: 'flow-id'
            instanceId: 'instance-id'
            nodeId: 'to-node-id'

          @sut = new EngineBatch metadata
          @sut.write roller: 'coaster'

        describe 'when the stream ends', ->
          beforeEach (done) ->
            @sut.on 'data', (@envelope) => done()

          it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
            expect(@envelope).to.deep.equal
              topic: 'message-batch'
              devices: ['*']
              payload:
                messages: [{ roller: 'coaster' }]

        describe 'when we write a second time', ->
          beforeEach ->
            metadata =
              flowId: 'flow-id'
              instanceId: 'instance-id'
              nodeId: 'to-node-id'

            engine2 = new EngineBatch metadata
            engine2.write sabotage: "Why aren't you all listening - it's sabotage!"
            engine2.write null

            @sut.write null

          describe 'when the stream ends', ->
            beforeEach (done) ->
              @sut.on 'data', (@envelope) => done()

            it 'should not emit anything from engine2', ->
              expect(@engine2Data).not.to.exist

            it 'should emit an envelope containing the 1 envelope(s) it recieved', ->
              expect(@envelope).to.deep.equal
                topic: 'message-batch'
                devices: ['*']
                payload:
                  messages: [
                    { roller: 'coaster' }
                    {sabotage: "Why aren't you all listening - it's sabotage!"}
                  ]
