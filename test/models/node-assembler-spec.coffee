_ = require 'lodash'
{Transform, PassThrough, Writable, Readable} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler-spec')
TestStream = require '../helpers/test-stream'

NodeAssembler = require '../../src/models/node-assembler'

describe 'NodeAssembler', ->
  describe '->assembleNodes', ->
    beforeEach ->
      @EngineDataNodeClass = sinon.stub()
      @EngineDebugNodeClass = sinon.stub()
      @EngineOutputNodeClass = sinon.stub()
      @EnginePulseNodeClass = sinon.stub()

      @NanocyteNodeWrapper =
        wrap: sinon.stub()

      @WrappedPassThrough = sinon.stub()
      @NanocyteNodeWrapper.wrap.withArgs(PassThrough).returns @WrappedPassThrough

      @SelectiveCollect = SelectiveCollect = sinon.stub()
      @WrappedSelectiveCollect = sinon.stub()
      @NanocyteNodeWrapper.wrap.withArgs(@SelectiveCollect).returns @WrappedSelectiveCollect

      @Trigger = Trigger = sinon.stub()
      @WrappedTrigger = sinon.stub()
      @NanocyteNodeWrapper.wrap.withArgs(@Trigger).returns @WrappedTrigger


      class ComponentLoader
        getComponentMap: =>
          {
            'nanocyte-component-pass-through': PassThrough
            'nanocyte-component-selective-collect': SelectiveCollect
            'nanocyte-component-trigger': Trigger
          }

      @sut = new NodeAssembler {},
        ComponentLoader: ComponentLoader
        EngineDataNode: @EngineDataNodeClass
        EngineDebugNode: @EngineDebugNodeClass
        EngineOutputNode: @EngineOutputNodeClass
        EnginePulseNode: @EnginePulseNodeClass
        NanocyteNodeWrapper: @NanocyteNodeWrapper


      @nodes = @sut.assembleNodes()

    it 'should return a map with the correct classes', ->
      expect(@nodes['engine-data']).to.equal @EngineDataNodeClass
      expect(@nodes['engine-debug']).to.equal @EngineDebugNodeClass
      expect(@nodes['engine-output']).to.equal @EngineOutputNodeClass
      expect(@nodes['engine-pulse']).to.equal @EnginePulseNodeClass

      expect(@nodes['nanocyte-component-pass-through']).to.equal @WrappedPassThrough
      expect(@nodes['nanocyte-component-selective-collect']).to.equal @WrappedSelectiveCollect
      expect(@nodes['nanocyte-component-trigger']).to.equal @WrappedTrigger
