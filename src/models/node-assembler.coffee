{PassThrough} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:node-assembler')
debugStream = require('debug-stream')('nanocyte-engine-simple:node-assembler')
ErrorStream = require './error-stream'
_ = require 'lodash'

class NodeAssembler
  constructor: (options, dependencies={}) ->
    {@OutputNodeWrapper,@DatastoreGetStream,@NanocyteNodeWrapper} = dependencies
    @NanocyteNodeWrapper ?= require './nanocyte-node-wrapper'
    @DatastoreGetStream   ?= require './datastore-get-stream'

    {@EngineData,@EngineDebug,@EngineOutput,@EnginePulse,@EngineThrottle} = dependencies
    @EngineData     ?= require './engine-data'
    @EngineDebug    ?= require './engine-debug'
    @EngineOutput   ?= require './engine-output'
    @EnginePulse    ?= require './engine-pulse'
    @EngineThrottle ?= require './engine-throttle'

    {@PassThrough} = dependencies
    @BodyParser         ?= require 'nanocyte-component-body-parser'
    @Broadcast          ?= require 'nanocyte-component-broadcast'
    @Change             ?= require 'nanocyte-component-change'
    @ClearData          ?= require 'nanocyte-component-clear-data'
    @ClearIfLengthGreaterThanMaxElsePassThrough ?=
      require 'nanocyte-component-clear-if-length-greater-than-max-else-pass-through'
    @Collect                           ?= require 'nanocyte-component-collect'
    @ConfigAsMessage                   ?= require 'nanocyte-component-config-as-message'
    @ContainsAllKeys                   ?= require 'nanocyte-component-contains-all-keys'
    @DataAsMessage                     ?= require 'nanocyte-component-data-as-message'
    @Demultiplex                       ?= require 'nanocyte-component-demultiplex'
    @Equal                             ?= require 'nanocyte-component-equal'
    @FlowMetricStart                   ?= require 'nanocyte-component-flow-metric-start'
    @FlowMetricStop                    ?= require 'nanocyte-component-flow-metric-stop'
    @Function                          ?= require 'nanocyte-component-function'
    @GetKeyFromData                    ?= require 'nanocyte-component-get-key-from-data'
    @GreaterThan                       ?= require 'nanocyte-component-greater-than'
    @HttpFormatter                     ?= require 'nanocyte-component-http-formatter'
    @HttpRequest                       ?= require 'nanocyte-component-http-request'
    @IntervalRegister                  ?= require 'nanocyte-component-interval-register'
    @IntervalUnregister                ?= require 'nanocyte-component-interval-unregister'
    @LessThan                          ?= require 'nanocyte-component-less-than'
    @MapMessageToKey                   ?= require 'nanocyte-component-map-message-to-key'
    @Math                              ?= require 'nanocyte-component-math'
    @MeshbluOutput                     ?= require 'nanocyte-component-meshblu-output'
    @NotEqual                          ?= require 'nanocyte-component-not-equal'
    @Null                              ?= require 'nanocyte-component-null'
    @OctobluChannelRequestFormatter    ?= require 'nanocyte-component-octoblu-channel-request-formatter'
    @OnStart                           ?= require 'nanocyte-component-onstart'
    @PassThrough                       ?= require 'nanocyte-component-pass-through'
    @PassThroughIfLengthGreaterThanMin ?= require 'nanocyte-component-pass-through-if-length-greater-than-min'
    @Pluck                             ?= require 'nanocyte-component-pluck'
    @PushMessageOnData                 ?= require 'nanocyte-component-push-message-on-data'
    @Range                             ?= require 'nanocyte-component-range'
    @Sample                            ?= require 'nanocyte-component-sample'
    @SelectiveCollect                  ?= require 'nanocyte-component-selective-collect'
    @Sentiment                         ?= require 'nanocyte-component-sentiment'
    @ShiftSend                         ?= require 'nanocyte-component-shift-send'
    @ShiftMessages                     ?= require 'nanocyte-component-shift-messages'
    @Template                          ?= require 'nanocyte-component-template'
    @Trigger                           ?= require 'nanocyte-component-trigger'
    @Unique                            ?= require 'nanocyte-component-unique'
    @UseStaticMessage                  ?= require 'nanocyte-component-use-static-message'

  assembleNodes: =>
    'engine-data':   @buildEngineData()
    'engine-debug':  @buildEngineDebug()
    'engine-output': @buildEngineOutput()
    'engine-pulse':  @buildEnginePulse()
    'nanocyte-component-body-parser':           @wrapNanocyte @BodyParser
    'nanocyte-component-broadcast':             @wrapNanocyte @Broadcast
    'nanocyte-component-change':                @wrapNanocyte @Change
    'nanocyte-component-clear-data':            @wrapNanocyte @ClearData
    'nanocyte-component-clear-if-length-greater-than-max-else-pass-through':
      @wrapNanocyte @ClearIfLengthGreaterThanMaxElsePassThrough
    'nanocyte-component-collect':               @wrapNanocyte @Collect
    'nanocyte-component-config-as-message':     @wrapNanocyte @ConfigAsMessage
    'nanocyte-component-contains-all-keys':     @wrapNanocyte @ContainsAllKeys
    'nanocyte-component-data-as-message':       @wrapNanocyte @DataAsMessage
    'nanocyte-component-demultiplex':           @wrapNanocyte @Demultiplex
    'nanocyte-component-equal':                 @wrapNanocyte @Equal
    'nanocyte-component-get-key-from-data':     @wrapNanocyte @GetKeyFromData
    'nanocyte-component-greater-than':          @wrapNanocyte @GreaterThan
    'nanocyte-component-flow-metric-start':     @wrapNanocyte @FlowMetricStart
    'nanocyte-component-flow-metric-stop':      @wrapNanocyte @FlowMetricStop
    'nanocyte-component-function':              @wrapNanocyte @Function
    'nanocyte-component-http-formatter':        @wrapNanocyte @HttpFormatter
    'nanocyte-component-http-request':          @wrapNanocyte @HttpRequest
    'nanocyte-component-interval-register':     @wrapNanocyte @IntervalRegister
    'nanocyte-component-interval-unregister':   @wrapNanocyte @IntervalUnregister
    'nanocyte-component-less-than':             @wrapNanocyte @LessThan
    'nanocyte-component-map-message-to-key':    @wrapNanocyte @MapMessageToKey
    'nanocyte-component-math':                  @wrapNanocyte @Math
    'nanocyte-component-meshblu-output':        @wrapNanocyte @MeshbluOutput
    'nanocyte-component-not-equal':             @wrapNanocyte @NotEqual
    'nanocyte-component-null':                  @wrapNanocyte @Null
    'nanocyte-component-octoblu-channel-request-formatter':
      @wrapNanocyte @OctobluChannelRequestFormatter
    'nanocyte-component-onstart':               @wrapNanocyte @OnStart
    'nanocyte-component-pass-through':          @wrapNanocyte @PassThrough
    'nanocyte-component-pass-through-if-length-greater-than-min':
      @wrapNanocyte @PassThroughIfLengthGreaterThanMin
    'nanocyte-component-pluck':                 @wrapNanocyte @Pluck
    'nanocyte-component-push-message-on-data':  @wrapNanocyte @PushMessageOnData
    'nanocyte-component-range':                 @wrapNanocyte @Range
    'nanocyte-component-sample':                @wrapNanocyte @Sample
    'nanocyte-component-selective-collect':     @wrapNanocyte @SelectiveCollect
    'nanocyte-component-sentiment':             @wrapNanocyte @Sentiment
    'nanocyte-component-shift-send':            @wrapNanocyte @ShiftSend
    'nanocyte-component-shift-messages':        @wrapNanocyte @ShiftMessages
    'nanocyte-component-template':              @wrapNanocyte @Template
    'nanocyte-component-trigger':               @wrapNanocyte @Trigger
    'nanocyte-component-unique':                @wrapNanocyte @Unique
    'nanocyte-component-use-static-message':    @wrapNanocyte @UseStaticMessage

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
        .pipe debugStream()
        .pipe new @EngineThrottle
        .pipe debugStream()
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
