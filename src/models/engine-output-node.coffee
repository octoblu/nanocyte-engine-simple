{Writable} = require 'stream'

class EngineOutputNode extends Writable
  constructor: (options, dependencies={})->
    super objectMode: true
    EngineToNanocyteStream = dependencies.EngineToNanocyteStream
    EngineToNanocyteStream ?= require './engine-to-nanocyte-stream'
    @engineToNanocyteStream = new EngineToNanocyteStream
    console.log 'eat my shorts'

  _write: (message)->
    @engineToNanocyteStream.write message

module.exports = EngineOutputNode
