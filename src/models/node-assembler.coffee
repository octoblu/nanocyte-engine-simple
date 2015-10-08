{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler')
debugStream = require('debug-stream')('nanocyte-engine-simple:node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper, ComponentLoader} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreGetStream  ?= require './datastore-get-stream'
    ComponentLoader ?= require './component-loader'

    {@EngineData,@EngineDebug,@EngineOutput,@EnginePulse,@EngineThrottle} = dependencies
    @EngineData     ?= require './engine-data'
    @EngineDebug    ?= require './engine-debug'
    @EngineOutput   ?= require './engine-output'
    @EnginePulse    ?= require './engine-pulse'
    @EngineThrottle ?= require './engine-throttle'

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
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      engineData = new @EngineData
      datastoreGetStream.pipe engineData

  buildEngineDebug: =>
    onEnvelope: (envelope) =>
      datastoreGetStream  = new @DatastoreGetStream
      datastoreGetStream.write envelope
      datastoreGetStream
        .pipe new @EngineDebug
        .pipe new @DatastoreGetStream
        .pipe new @EngineThrottle
        .pipe new @EngineOutput

  buildEngineOutput: =>
    onEnvelope: (envelope) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope
      datastoreGetStream
        .pipe new @EngineThrottle
        .pipe new @EngineOutput

  buildEnginePulse: =>
    onEnvelope: (envelope) =>
      data = new @DatastoreGetStream
      data.write envelope
      data
        .pipe new @EnginePulse
        .pipe new @DatastoreGetStream
        .pipe new @EngineThrottle
        .pipe new @EngineOutput

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope, callback) =>
      datastoreGetStream = new @DatastoreGetStream
      datastoreGetStream.write envelope

      node = new @NanocyteNodeWrapper nodeClass: nodeClass

      node.on 'readable', =>
        read = node.read()
        return if _.isNull read
        callback null, read

      node.on 'error', (error) =>
        errorStream = new ErrorStream error: error
        errorStream.write envelope

        errorStream
          .pipe new @DatastoreGetStream
          .pipe new @EngineDebug
          .pipe new @DatastoreGetStream
          .pipe new @EngineThrottle
          .pipe new @EngineOutput

      node.initialize()
      datastoreGetStream.pipe node

module.exports = NodeAssembler
