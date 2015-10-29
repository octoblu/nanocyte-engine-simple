EngineInputNode = require '../../src/models/engine-input-node'
TestStream = require '../helpers/test-stream'

describe 'EngineInputNode', ->
  beforeEach ->

  it 'should exist', ->
    expect(EngineInputNode).to.exist

  describe 'when messaged to with a nanocyte envelope', ->
    beforeEach ->
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
      @sut.message @envelope

    it 'should not die', ->
      expect(true).to.be.true
