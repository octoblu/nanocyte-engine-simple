_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Transform
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: ({config, message}, enc, done) =>
    console.log "config is:", config, message
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message
    @push null
    done()

module.exports = EngineOutput
