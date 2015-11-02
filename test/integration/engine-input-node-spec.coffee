EngineInputNode = require '../../src/models/engine-input-node'
TestStream = require '../helpers/test-stream'
_ = require 'lodash'
describe 'EngineInputNode', ->
  beforeEach ->

  it 'should exist', ->
    expect(EngineInputNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    @timeout 50000
    beforeEach (done) ->
      @messages = []
      @envelope =
        metadata:
          toNodeId: 'engine-input'
          flowId: 'equals-train'
          instanceId: 'engine-in-a-vat'
        message:
          hi: true
          payload:
            from: 'e4a39630-7d06-11e5-a5f0-630ba8cd1e4b'

      @sut = new EngineInputNode
      @responseStream = @sut.message @envelope
      @responseStream.on 'data', (message) => @messages.push message
      @responseStream.on 'end', done

    it 'should hit engine-debug exactly 6 times', ->
      console.log  JSON.stringify @messages, null, 2
