class NodeAssembler
  constructor: (options, dependencies={}) ->
    @NanocyteNodeWrapper = dependencies.NanocyteNodeWrapper || require '../../src/models/nanocyte-node-wrapper'
    @NanocyteDebug = dependencies.NanocyteDebug
  assembleNodes: =>
    'nanocyte-node-debug': new @NanocyteNodeWrapper @NanocyteDebug
    'meshblu-output': onEnvelope: => false


module.exports = NodeAssembler
