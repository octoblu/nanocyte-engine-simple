_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-update')

class EngineUpdate extends Transform
  constructor: (@metadata={}, dependencies={})->
    super objectMode: true
    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: ({config, message}, enc, next) =>
    debug {@metadata, config, message}
    {device, update} = message
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.update device, update, (error) =>
      @push null
      next(error)

module.exports = EngineUpdate
