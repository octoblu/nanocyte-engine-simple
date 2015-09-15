class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@NanocyteNodeWrapper,@OutputNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require '../../src/models/nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require '../../src/models/output-node-wrapper'

    {@DebugNode,@TriggerNode,@OutputNode} = dependencies

  assembleNodes: =>
    'nanocyte-node-debug':   new @NanocyteNodeWrapper @DebugNode
    'nanocyte-node-trigger': new @NanocyteNodeWrapper @TriggerNode
    'meshblu-output':        new @OutputNodeWrapper @OutputNode

module.exports = NodeAssembler
