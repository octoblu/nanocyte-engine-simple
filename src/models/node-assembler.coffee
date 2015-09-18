class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @OutputNodeWrapper   ?= require './output-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@DebugNode,@TriggerNode,@OutputNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @TriggerNode ?= require 'nanocyte-node-trigger'
    @OutputNode  ?= require './meshblu-output-node'

  assembleNodes: =>
    'nanocyte-node-debug':   @wrapNanocyte @DebugNode
    'nanocyte-node-trigger': @wrapNanocyte @TriggerNode
    'engine-output':        new @OutputNodeWrapper   nodeClass: @OutputNode # onEnvelope: => console.log 'engine-output'
    'engine-debug':         new @OutputNodeWrapper   nodeClass: @OutputNode
    'engine-pulse':         new @OutputNodeWrapper   nodeClass: @OutputNode # onEnvelope: => console.log 'engine-pulse'

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: nodeClass

      node.on 'readable', =>
        callback null, node.read()

      datastoreGetStream.pipe node


module.exports = NodeAssembler
