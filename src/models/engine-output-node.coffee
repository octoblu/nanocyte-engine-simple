class EngineOutputNode
  constructor: (dependencies={})->
    {@EngineBatch, @SerializerStream, @EngineToNanocyteStream, @EngineOutput} = dependencies
    @EngineBatch ?= require './engine-batch'
    @SerializerStream ?= require './serializer-stream'
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @EngineOutput ?= require './engine-output'

  message: ({metadata, message})=>
    engineBatch = new @EngineBatch metadata

    engineBatch
      .pipe new @SerializerStream metadata
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineOutput metadata

    engineBatch.write message

module.exports = EngineOutputNode
