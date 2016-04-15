_ = require 'lodash'
{Transform} = require 'stream'
debug = require('debug')('nanocyte-engine-simple:engine-output')

class EngineOutput extends Transform
  constructor: (@metadata={}, dependencies={})->
    super objectMode: true
    {@MeshbluHttp} = dependencies
    @MeshbluHttp ?= require 'meshblu-http'

  _transform: ({config, message}, enc, next) =>
    debug {@metadata, config, message}
    @_insertMetadata message, config
    meshbluHttp = new @MeshbluHttp config
    meshbluHttp.message message, (error) =>
      @push null
      next error if next?

  _insertMetadata: (message, config) =>
    {devices}           = message
    {forwardMetadataTo} = config
    {fromNodeId}        = @metadata

    return if _.isEmpty _.intersection devices, forwardMetadataTo
    _.set message, 'metadata.flow.fromNodeId', fromNodeId

module.exports = EngineOutput
