class NodeAssembler
  constructor: (options, dependencies={}) ->
    @NanocyteNodeWrapper = dependencies.NanocyteNodeWrapper || require '../../src/models/nanocyte-node-wrapper'
    @OutputNodeWrapper = dependencies.OutputNodeWrapper || require '../../src/models/output-node-wrapper'

    @NanocyteDebug = dependencies.NanocyteDebug
    @OutputNode = dependencies.OutputNode

  assembleNodes: =>
    'nanocyte-node-debug': new @NanocyteNodeWrapper @NanocyteDebug
    'meshblu-output': new @OutputNodeWrapper @OutputNode


module.exports = NodeAssembler
