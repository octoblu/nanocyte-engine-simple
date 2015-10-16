{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-node-assembler')
debugStream = require('debug-stream')('nanocyte-node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'
uuid = require 'node-uuid'
Combine = require 'stream-combiner2'
class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@DatastoreCheckKeyStream} = dependencies
    {@NanocyteNodeWrapper,ComponentLoader} = dependencies
    {@EngineToNanocyteStream, @MetadataStream} = dependencies

    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreCheckKeyStream  ?= require './datastore-check-key-stream'

    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @NanocyteToEngineStream ?= require './nanocyte-to-engine-stream'

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
    onEnvelope: (envelope) =>
      debugOutputStream = debugStream('engine-data')
      dataStream.write envelope
      return dataStream

  buildEngineDebug: =>
    onEnvelope: ({metadata,message}) =>
      outputMetadata = _.defaults nodeId: 'engine-output', metadata
      debugOutputStream =
        Combine(
          debugStream('engine-debugOutput')
          new @EngineToNanocyteStream(metadata)
          new @DatastoreCheckKeyStream(metadata)
          new @EngineDebug(metadata)
          @buildEngineOutputStream(outputMetadata)
        )

      debugOutputStream.write message
      return debugOutputStream

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
     new @EngineToNanocyteStream(metadata)
     debugStream('output-after-nanocyte')
     new @EngineOutput(metadata)
   )

  buildEnginePulse: =>
    onEnvelope: ({message, metadata}) =>
      outputMetadata = _.defaults nodeId: 'engine-output', metadata
      pulseStream =
        Combine(
          new @EngineToNanocyteStream(metadata)
          new @DatastoreCheckKeyStream(metadata)
          new @EnginePulse(metadata)
          @buildEngineOutputStream outputMetadata
        )

      pulseStream.write message
      return pulseStream

  wrapNanocyte: (nodeClass) =>
    onEnvelope: ({metadata, message}) =>
      nanocyteStream =
        Combine(
          debugStream('engine-to-nanocyte')
          new @EngineToNanocyteStream(metadata)
          debugStream('nanocyte-envelope')
          new nodeClass
          debugStream('after-nanocyte')
          new @NanocyteToEngineStream(metadata)
        )

      nanocyteStream.write message

      return nanocyteStream

module.exports = NodeAssembler
