{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler')
debugStream = require('debug-stream')('nanocyte-engine-simple:node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'
Combine = require 'stream-combiner2'
class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@DatastoreCheckKeyStream} = dependencies
    {@NanocyteNodeWrapper,ComponentLoader} = dependencies
    {@EnvelopeStream, @MetadataStream} = dependencies

    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreCheckKeyStream  ?= require './datastore-check-key-stream'

    @EnvelopeStream ?= require './envelope-stream'
    @MetadataStream ?= require './metadata-stream'

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
    @engineData = @buildEngineData()
    @engineDebug = @buildEngineDebug()
    @engineOutput = @buildEngineOutput()
    @enginePulse = @buildEnginePulse()

    engineComponents =
      'engine-data':   => @engineData
      'engine-debug':  => @engineDebug
      'engine-output': => @engineOutput
      'engine-pulse':  => @enginePulse

    componentMap = @componentLoader.getComponentMap()

    wrappedComponents = _.transform componentMap, (result, value, key) =>
      result[key] = @wrapNanocyte value

    assembledNodes = _.extend {}, wrappedComponents, engineComponents
    return assembledNodes

  buildEngineData: =>
    # Combine new @DatastoreGetStream, new @EngineData

  buildEngineDebug: =>
    # Combine(
    #   new @DatastoreGetStream
    #   new @DatastoreCheckKeyStream
    #   new @EngineDebug
    #   new @EngineBatch
    #   new @DatastoreGetStream
    #   new @EngineOutput
    # )

  buildEngineOutput: =>
    # Combine(
    #   new @DatastoreGetStream
    #   new @EngineThrottle
    #   new @EngineOutput
    # )

  buildEnginePulse: =>
      # Combine(
      #   new @DatastoreGetStream
      #   new @DatastoreCheckKeyStream
      #   new @EnginePulse
      #   new @EngineBatch
      #   new @DatastoreGetStream
      #   new @EngineOutput
      # )

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope) =>
      nanocyteStream =
        Combine(
          new @EnvelopeStream(envelope.metadata)
          new @NanocyteNodeWrapper(nodeClass: nodeClass)
          new @EnvelopeStream(envelope.metadata)
        )

      nanocyteStream.write envelope.message

      return nanocyteStream

module.exports = NodeAssembler
