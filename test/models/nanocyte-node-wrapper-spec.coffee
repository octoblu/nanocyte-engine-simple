NanocyteNodeWrapper = require '../../src/models/nanocyte-node-wrapper'

describe 'NanocyteNodeWrapper', ->
  describe '->constructor', ->
    beforeEach ->
      @sut = new NanocyteNodeWrapper
    it 'should exist', ->
      expect(@sut).to.exist

    it 'should do things', ->
      expect(@sut.doTheUsefulThings).to.exist
