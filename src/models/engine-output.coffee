{Writable} = require 'stream'

class EngineOutput extends Writable
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _write: (envelope, enc, done) =>
    {config,message} = envelope
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message

module.exports = EngineOutput
