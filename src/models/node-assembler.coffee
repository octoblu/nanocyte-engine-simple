debug = require('debug')('nanocyte-node-assembler')
debugStream = require('debug-stream')('nanocyte-node-assembler')
_ = require 'lodash'
uuid = require 'node-uuid'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@EngineDataNode, @EngineDebugNode, @EngineOutputNode, @EnginePulseNode, @EngineBatchNode, @NanocyteNodeWrapper} = dependencies
    @EngineBatchNode ?= require './engine-batch-node'
    @EngineDataNode ?= require './engine-data-node'
    @EngineDebugNode ?= require './engine-debug-node'
    @EngineBatchNode ?= require './engine-batch-node'
    @EngineOutputNode ?= require './engine-output-node'
    @EnginePulseNode ?= require './engine-pulse-node'
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'

    {ComponentLoader} = dependencies
    ComponentLoader ?= require './component-loader'
    @componentLoader = new ComponentLoader

  assembleNodes: =>
    engineComponents =
      'engine-data':   @EngineDataNode
      'engine-debug':  @EngineDebugNode
      'engine-output': @EngineOutputNode
      'engine-pulse':  @EnginePulseNode
      'engine-batch':  @EngineBatchNode

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, NanocyteClass, nanocyteType) =>
      result[nanocyteType] = @wrapNanocyte NanocyteClass
    assembledNodes = _.extend {}, wrappedComponents, engineComponents

    # assembledNodes['nanocyte-component-trigger'] = assembledNodes['nanocyte-component-pass-through']
    return assembledNodes

  wrapNanocyte: (NanocyteClass) =>
    return @NanocyteNodeWrapper.wrap NanocyteClass

module.exports = NodeAssembler
