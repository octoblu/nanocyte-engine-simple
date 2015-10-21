class EngineOutputNode
  constructor: (dependencies={})->
    @EngineToNanocyteStream = dependencies.EngineToNanocyteStream
    @EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'

  message: ({metadata, message})->
    engineToNanocyteStream = new @EngineToNanocyteStream metadata
    engineToNanocyteStream.write message

module.exports = EngineOutputNode
