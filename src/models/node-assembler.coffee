{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler')
debugStream = require('debug-stream')('nanocyte-engine-simple:node-assembler')

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@EngineData,@EngineDebug,@EngineOutput,@EnginePulse} = dependencies
    @EngineData   ?= require './engine-data'
    @EngineDebug  ?= require './engine-debug'
    @EngineOutput ?= require './engine-output'
    @EnginePulse  ?= require './engine-pulse'

    {@DebugNode,@SelectiveCollect,@TriggerNode} = dependencies
    @ClearData        ?= require 'nanocyte-component-clear-data'
    @ContainsAllKeys  ?= require 'nanocyte-component-contains-all-keys'
    @SelectiveCollect ?= require 'nanocyte-component-selective-collect'
    @DebugNode        ?= require 'nanocyte-node-debug'
    @TriggerNode      ?= require 'nanocyte-node-trigger'

  assembleNodes: =>
    'engine-data':           @buildEngineData()
    'engine-debug':          @buildEngineDebug()
    'engine-output':         @buildEngineOutput()
    'engine-pulse':          @buildEnginePulse()
    'nanocyte-component-selective-collect': @wrapNanocyte @SelectiveCollect
    'nanocyte-component-clear-data': @wrapNanocyte @ClearData
    'nanocyte-component-contains-all-keys': @wrapNanocyte @ContainsAllKeys
    'nanocyte-node-debug':   @wrapNanocyte @DebugNode
    'nanocyte-node-trigger': @wrapNanocyte @TriggerNode

  buildEngineData: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineData = new @EngineData
      datastoreGetStream.pipe engineData

  buildEngineDebug: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineDebug         = new @EngineDebug
      datastoreGetStream2 = new @DatastoreGetStream
      engineOutput        = new @EngineOutput
      datastoreGetStream.pipe(engineDebug).pipe(datastoreGetStream2).pipe(engineOutput)

  buildEngineOutput: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineOutput = new @EngineOutput
      datastoreGetStream.pipe engineOutput

  buildEnginePulse: =>
    onEnvelope: (envelope) =>
      data = new @DatastoreGetStream
      data.write envelope
      data
        .pipe new @EnginePulse
        .pipe new @DatastoreGetStream
        .pipe new @EngineOutput

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: nodeClass

      node.on 'readable', =>
        callback null, node.read()

      datastoreGetStream.pipe(debugStream()).pipe node

module.exports = NodeAssembler
