class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream} = dependencies
    @OutputNodeWrapper   ?= require './output-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@DebugNode,@OutputNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':  onEnvelope: (envelope, callback) =>
                              datastoreGetStream = new @DatastoreGetStream envelope: envelope
                              node = new @DebugNode

                              node.messageOutputStream.on 'readable', =>
                                callback null, node.messageOutputStream.read()

                              datastoreGetStream.pipe node

    'meshblu-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

module.exports = NodeAssembler
