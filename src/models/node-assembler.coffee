class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@NanocyteNodeWrapper,@OutputNodeWrapper,@DatastoreInStream} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require './output-node-wrapper'
    @DatastoreInStream   ?= require './datastore-in-stream'

    {@DebugNode,@OutputNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':  onEnvelope: (envelope, callback) =>
                              datastoreInStream = new @DatastoreInStream
                              datastoreInStream.onEnvelope envelope, (error, envelope) =>
                                wrapper = new @NanocyteNodeWrapper nodeClass: @DebugNode
                                wrapper.onEnvelope envelope, callback

    'meshblu-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

module.exports = NodeAssembler
