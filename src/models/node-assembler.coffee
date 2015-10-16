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
    onEnvelope: (envelope) =>
      debugOutputStream = debugStream('engine-debugOutput')
      debugOutputStream.write envelope
      return debugOutputStream

  buildEngineOutput: =>
    onEnvelope: (envelope) =>
      outputStream =
        Combine(
          new @EngineToNanocyteStream(envelope.metadata)
          new debugStream('engine-output-envelope')
          new @EngineOutput(envelope.metadata)
        )

      outputStream.write envelope.message
      return outputStream

  buildEnginePulse: =>
    onEnvelope: (envelope) =>
      pulseStream =
        Combine(
          new @EngineToNanocyteStream(envelope.metadata)
          new @DatastoreCheckKeyStream(envelope.metadata)
          new @EnginePulse(envelope.metadata)
        )

      pulseStream.write envelope.message
      return pulseStream

  wrapNanocyte: (nodeClass) =>
    onEnvelope: (envelope) =>
      nanocyteStream =
        Combine(
          debugStream('engine-to-nanocyte')
          new @EngineToNanocyteStream(envelope.metadata)
          debugStream('nanocyte-envelope')
          new nodeClass
          debugStream('after-nanocyte')
          new @NanocyteToEngineStream(envelope.metadata)
          debugStream('after-nanocyte-to-engine')
        )

      nanocyteStream.write envelope.message

      return nanocyteStream

module.exports = NodeAssembler
