_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Transform
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: ({config, message}, enc, next) =>
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message, (error) =>
      @push null
      next(error) if error?

module.exports = EngineOutput
