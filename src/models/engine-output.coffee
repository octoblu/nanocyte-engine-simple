{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Transform
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: (envelope, enc, done) =>
    {config, message} = envelope
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message, (error, response)=>
      done()
      @push null

module.exports = EngineOutput
