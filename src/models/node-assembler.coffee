{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-node-assembler')
debugStream = require('debug-stream')('nanocyte-node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'
uuid = require 'node-uuid'
Combine = require 'stream-combiner2'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@EngineDataNode, @EngineDebugNode, @EngineOutputNode, @EnginePulseNode, @NanocyteNodeWrapper} = dependencies
    @EngineDataNode ?= require './engine-data-node'
    @EngineDebugNode ?= require './engine-debug-node'
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

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, NanocyteClass, nanocyteType) =>
      result[nanocyteType] = @wrapNanocyte NanocyteClass

    assembledNodes = _.extend {}, wrappedComponents, engineComponents
    return assembledNodes

  wrapNanocyte: (NanocyteClass) =>    
    return @NanocyteNodeWrapper.wrap NanocyteClass

module.exports = NodeAssembler
