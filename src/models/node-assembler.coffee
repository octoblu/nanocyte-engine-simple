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
    engineComponents =
      'engine-data':   @buildEngineData()
      'engine-debug':  @buildEngineDebug()
      'engine-output': @buildEngineOutput()
      'engine-pulse':  @buildEnginePulse()

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, value, key) =>
      result[key] = @wrapNanocyte value

    assembledNodes = _.extend {}, wrappedComponents, engineComponents
    return assembledNodes

  buildEngineData: =>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineData = new @EngineData
      datastoreGetStream.pipe engineData
        .on 'end', => end null, envelope

  buildEngineDebug: =>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream  = new @DatastoreGetStream
      datastoreGetStream.write envelope
      datastoreGetStream
        .pipe new @DatastoreCheckKeyStream
        .pipe new @EngineDebug
        .pipe new @EngineBatch
        .pipe new @DatastoreGetStream
        .pipe new @EngineOutput
        .on 'end', => end null, envelope

  buildEngineOutput: =>
    onEnvelope: (envelope, next, end) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope
      datastoreGetStream
        .pipe new @EngineThrottle
        .pipe new @EngineOutput
        .on 'end', => end null, envelope

  buildEnginePulse: =>
    onEnvelope: (envelope, next, end) =>
      data = new @DatastoreGetStream
      data.write envelope
      data
        .pipe new @DatastoreCheckKeyStream
        .pipe new @EnginePulse
        .pipe new @EngineBatch
        .pipe new @DatastoreGetStream
        .pipe new @EngineOutput
        .on 'end', => end null, envelope

  wrapNanocyte: (nodeClass) =>
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
          .pipe new @EngineOutput

      node.initialize()
      datastoreGetStream.pipe node

module.exports = NodeAssembler
