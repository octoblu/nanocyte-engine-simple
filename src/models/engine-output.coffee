{Writable} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Writable
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _write: (envelope, enc, done) =>
    debug '_write', envelope
    {config,message} = envelope
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message

module.exports = EngineOutput
