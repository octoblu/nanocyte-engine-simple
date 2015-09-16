class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require './output-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@DebugNode,@OutputNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':  onEnvelope: (envelope, callback) =>
                              datastoreGetStream = new @DatastoreGetStream
                              datastoreGetStream.write envelope

                              node = new @NanocyteNodeWrapper nodeClass: @DebugNode

                              node.messageOutStream.on 'readable', =>
                                callback null, node.messageOutStream.read()

                              datastoreGetStream.pipe node

    'meshblu-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

module.exports = NodeAssembler
