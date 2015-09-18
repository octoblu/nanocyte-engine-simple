class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@EngineDebug,@EngineOutput,@EnginePulse} = dependencies
    @EngineDebug  ?= require './engine-debug'
    @EngineOutput ?= require './engine-output'
    @EnginePulse  ?= require './engine-pulse'

    {@DebugNode,@TriggerNode} = dependencies
    @DebugNode   ?= require 'nanocyte-node-debug'
    @TriggerNode ?= require 'nanocyte-node-trigger'


  assembleNodes: =>
    'engine-output':         onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineOutput = new @EngineOutput
      datastoreGetStream.pipe engineOutput
    'engine-debug':          onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineDebug  = new @EngineDebug
      engineOutput = new @EngineOutput
      datastoreGetStream.pipe(engineDebug).pipe(engineOutput)
    'engine-pulse':          onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      enginePulse  = new @EnginePulse
      engineOutput = new @EngineOutput
      datastoreGetStream.pipe(enginePulse).pipe(engineOutput)
    'nanocyte-node-debug':   @wrapNanocyte @DebugNode
    'nanocyte-node-trigger': @wrapNanocyte @TriggerNode

  wrapAndDatastore: =>

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: nodeClass

      node.on 'readable', =>
        callback null, node.read()

      datastoreGetStream.pipe node


module.exports = NodeAssembler
