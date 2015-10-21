{Writable} = require 'stream'
class EngineOutputNode extends Writable
  constructor: (dependencies={})->
    super objectMode: true
    {@EngineBatch, @SerializerStream, @EngineToNanocyteStream, @EngineOutput} = dependencies
    @EngineBatch ?= require './engine-batch'
    @SerializerStream ?= require './serializer-stream'
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @EngineOutput ?= require './engine-output'

  _write: (envelope, enc, next) =>
    @message envelope
    next()

  message: ({metadata, message})=>
    engineBatch = new @EngineBatch metadata

    engineBatch
      .pipe new @SerializerStream metadata
      .pipe new @EngineToNanocyteStream metadata
      .pipe new @EngineOutput metadata

    engineBatch.write message

module.exports = EngineOutputNode
