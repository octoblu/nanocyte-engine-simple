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
    'nanocyte-node-debug':   @wrapNanocyte()
    'nanocyte-node-trigger': @wrapNanocyte()
    'engine-output':        new @OutputNodeWrapper   nodeClass: @OutputNode

  wrapNanocyte: =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: @DebugNode

      node.on 'readable', =>
        callback null, node.read()

      datastoreGetStream.pipe node


module.exports = NodeAssembler
