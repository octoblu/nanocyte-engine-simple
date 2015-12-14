debug = require('debug')('nanocyte-node-assembler')
debugStream = require('debug-stream')('nanocyte-node-assembler')
_ = require 'lodash'
uuid = require 'node-uuid'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@EngineDataNode, @EngineDebugNode, @EngineOutputNode, @EnginePulseNode, @EngineBatchNode, @EngineInputNode, @nanocyteNodeWrapper} = dependencies
    @EngineBatchNode     ?= require './engine-batch-node'
    @EngineDataNode      ?= require './engine-data-node'
    @EngineDebugNode     ?= require './engine-debug-node'
    @EngineBatchNode     ?= require './engine-batch-node'
    @EngineOutputNode    ?= require './engine-output-node'
    @EngineInputNode     ?= require './engine-input-node'
    @EnginePulseNode     ?= require './engine-pulse-node'
    @nanocyteNodeWrapper ?= new (require './nanocyte-node-wrapper') options, dependencies

    {ComponentLoader} = dependencies
    ComponentLoader  ?= require './component-loader'
    @componentLoader  = new ComponentLoader options, dependencies

  assembleNodes: =>
    engineComponents =
      'engine-data'  : @EngineDataNode
      'engine-debug' : @EngineDebugNode
      'engine-output': @EngineOutputNode
      'engine-pulse' : @EnginePulseNode
      'engine-batch' : @EngineBatchNode
      'engine-input' : @EngineInputNode

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, NanocyteClass, nanocyteType) =>
      result[nanocyteType] = @wrapNanocyte NanocyteClass
    assembledNodes = _.extend {}, wrappedComponents, engineComponents

    return assembledNodes

  wrapNanocyte: (NanocyteClass) =>
    return @nanocyteNodeWrapper.wrap NanocyteClass

module.exports = NodeAssembler
