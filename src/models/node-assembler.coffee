class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@NanocyteNodeWrapper,@OutputNodeWrapper,@DatastoreInStream} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require './output-node-wrapper'

    {@DebugNode,@TriggerNode,@OutputNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':  onEnvelope: (callback) =>
                              datastoreInStream = new @DatastoreInStream
                              datastoreInStream.onEnvelope (error, envelope) =>
                                wrapper = new @NanocyteNodeWrapper {}
                                wrapper.onEnvelope envelope, callback

    'meshblu-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

module.exports = NodeAssembler
