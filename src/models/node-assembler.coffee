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
    'engine-debug':          @buildEngineDebug()
    'engine-output':         @buildEngineOutput()
    'engine-pulse':          @buildEnginePulse()
    'nanocyte-node-debug':   @wrapNanocyte @DebugNode
    'nanocyte-node-trigger': @wrapNanocyte @TriggerNode

  buildEngineDebug: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      datastoreGetStream2 = new @DatastoreGetStream

      engineDebug  = new @EngineDebug
      engineOutput = new @EngineOutput
      datastoreGetStream.pipe(engineDebug).pipe(datastoreGetStream2).pipe(engineOutput)

  buildEngineOutput: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineOutput = new @EngineOutput
      datastoreGetStream.pipe engineOutput

  buildEnginePulse: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      datastoreGetStream2 = new @DatastoreGetStream

      enginePulse  = new @EnginePulse
      engineOutput = new @EngineOutput
      datastoreGetStream.pipe(enginePulse).pipe(datastoreGetStream2).pipe(engineOutput)


  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: nodeClass

      node.on 'readable', =>
        callback null, node.read()

      datastoreGetStream.pipe node


module.exports = NodeAssembler
