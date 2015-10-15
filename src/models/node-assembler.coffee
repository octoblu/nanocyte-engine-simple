{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler')
debugStream = require('debug-stream')('nanocyte-engine-simple:node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@DatastoreCheckKeyStream} = dependencies
    {@NanocyteNodeWrapper,ComponentLoader} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreCheckKeyStream  ?= require './datastore-check-key-stream'
    @DatastoreGetStream  ?= require './datastore-get-stream'
    ComponentLoader ?= require './component-loader'

    {@EngineData,@EngineDebug,@EngineOutput,@EnginePulse,@EngineThrottle,@EngineBatch} = dependencies
    @EngineData     ?= require './engine-data'
    @EngineDebug    ?= require './engine-debug'
    @EngineOutput   ?= require './engine-output'
    @EnginePulse    ?= require './engine-pulse'
    @EngineThrottle ?= require './engine-throttle'
    @EngineBatch    ?= require './engine-batch'

    @componentLoader = new ComponentLoader

  assembleNodes: =>
    engineOutput = new @EngineOutput
    engineComponents =
      'engine-data':   @buildEngineData()
      'engine-debug':  @buildEngineDebug engineOutput
      'engine-output': @buildEngineOutput engineOutput
      'engine-pulse':  @buildEnginePulse engineOutput

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, value, key) =>
      result[key] = @wrapNanocyte value, engineOutput

    assembledNodes = _.extend {}, wrappedComponents, engineComponents
    return assembledNodes

  buildEngineData: =>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineData = new @EngineData
      datastoreGetStream.pipe engineData
      engineData.on 'end', => end null, envelope

  buildEngineDebug: (engineOutput)=>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream  = new @DatastoreGetStream
      datastoreGetStream.write envelope
      debugStream = datastoreGetStream
        .pipe new @DatastoreCheckKeyStream
        .pipe new @EngineDebug
        .pipe new @EngineBatch
        .pipe new @DatastoreGetStream

      debugStream.on 'end', => end null, envelope
      debugStream.pipe engineOutput

  buildEngineOutput: (engineOutput)=>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope
      outputStream = datastoreGetStream
        .pipe new @EngineThrottle

      outputStream.on 'end', => end null, envelope
      outputStream.pipe engineOutput

  buildEnginePulse: (engineOutput)=>
    onEnvelope: (envelope, next, end) =>
      data = new @DatastoreGetStream
      data.write envelope
      pulseStream = data
        .pipe new @DatastoreCheckKeyStream
        .pipe new @EnginePulse
        .pipe new @EngineBatch
        .pipe new @DatastoreGetStream

      pulseStream.on 'end', => end null, envelope
      pulseStream.pipe engineOutput

  wrapNanocyte: (nodeClass, engineOutput) =>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper
        nodeClass: nodeClass

      node.on 'readable', =>
        read = node.read()
        return if _.isNull read
        next null, read

      node.on 'end', => end null, envelope

      node.on 'error', (error) =>
        errorStream = new ErrorStream error: error
        errorStream.write envelope

        errorStream
          .pipe new @DatastoreGetStream
          .pipe new @EngineDebug
          .pipe new @EngineBatch
          .pipe new @DatastoreGetStream
          .pipe new @EngineThrottle
          .pipe engineOutput

      node.initialize()
      datastoreGetStream.pipe node

module.exports = NodeAssembler
