_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Transform
  constructor: (options={}, dependencies={})->
    super objectMode: true

    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: ({config, message}, enc, done) =>
    meshbluConfig = _.extend raw: true, config
    meshbluHttp = new @MeshbluHttp meshbluConfig
    meshbluHttp.message message
    done()

module.exports = EngineOutput
