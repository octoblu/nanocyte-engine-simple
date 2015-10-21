{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-node-assembler')
debugStream = require('debug-stream')('nanocyte-node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'
uuid = require 'node-uuid'
Combine = require 'stream-combiner2'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreCheckKeyStream} = dependencies
    {@NanocyteNodeWrapper,ComponentLoader} = dependencies
    {@EngineToNanocyteStream, @MetadataStream} = dependencies

    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreCheckKeyStream  ?= require './datastore-check-key-stream'

    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'
    @SerializerStream ?= require './serializer-stream'
    @ChristacheioStream ?= require './christacheio-stream'

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

    wrappedComponents = _.transform componentMap, (result, NanocyteClass, nanocyteType) =>
      result[nanocyteType] = @wrapNanocyte NanocyteClass

    assembledNodes = _.extend {}, wrappedComponents, engineComponents
    return assembledNodes

  buildEngineData: ()=>
    onEnvelope: ({metadata, message}) =>
      dataStream = debugStream('engine-data')
      dataStream
        .pipe new @EngineToNanocyteStream(metadata)
        .pipe new @EngineData(metadata)
      dataStream.write message

      return dataStream

  buildEngineDebug: =>
    onEnvelope: ({metadata,message}) =>
      debugStream = debugStream('engine-debug')
      debugStream
        .pipe new @EngineToNanocyteStream(metadata)
        .pipe new @DatastoreCheckKeyStream(metadata)
        .pipe new @EngineDebug(metadata)

      debugStream.write message

      return debugStream

  buildEngineOutput: =>
    onEnvelope: ({metadata, message}) =>
      outputStream = @buildEngineOutputStream metadata
      outputStream.write message
      return outputStream

  buildEngineOutputStream: (metadata) =>
    Combine(
      debugStream('before-batch')
      new @EngineBatch(metadata)
      debugStream('after-batch')
      new @SerializerStream(metadata)
      new @EngineToNanocyteStream(metadata)
      new @EngineOutput(metadata)
    )
    # outputStream = debugStream('engine-before-batch')
    # outputStream
    #   .pipe new @EngineBatch(metadata)
    #   .pipe debugStream('engine-after-batch')
    #   .pipe new @EngineToNanocyteStream(metadata)
    #   .pipe debugStream('output-after-nanocyte')
    #   .pipe new @EngineOutput(metadata)

    # return outputStream

  buildEnginePulse: =>
    onEnvelope: ({message, metadata}) =>
      outputMetadata = _.defaults nodeId: 'engine-output', metadata
      pulseStream = debugStream 'engine-pulse'
      pulseStream.write message
      pulseStream
        .pipe new @EngineToNanocyteStream(metadata)
        .pipe new @DatastoreCheckKeyStream(metadata)
        .pipe new @EnginePulse(metadata)
        .pipe @buildEngineOutputStream outputMetadata

  wrapNanocyte: (NanocyteClass) =>
    onEnvelope: ({metadata, message}) =>
      nanocyteStream = debugStream 'engine-to-nanocyte'
      nanocyteStream.write message
      nanocyteStream
        .pipe new @EngineToNanocyteStream(metadata)
        .pipe debugStream('nanocyte-envelope')
        .pipe new @ChristacheioStream(metadata)
        .pipe debugStream('after-christacheio')
        .pipe new NanocyteClass
        .pipe debugStream('after-nanocyte')
        .pipe new @NanocyteToEngineStream(metadata)


module.exports = NodeAssembler
