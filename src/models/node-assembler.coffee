class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@NanocyteNodeWrapper,@OutputNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require './output-node-wrapper'

    {@DebugNode,@TriggerNode,@OutputNode} = dependencies
    @DebugNode   ?= require './unwrapped-debug-node-to-be-replaced'
    @TriggerNode ?= require './unwrapped-trigger-node-to-be-replaced'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':   new @NanocyteNodeWrapper nodeClass: @DebugNode
    'nanocyte-node-trigger': new @NanocyteNodeWrapper nodeClass: @TriggerNode
    'meshblu-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

module.exports = NodeAssembler
