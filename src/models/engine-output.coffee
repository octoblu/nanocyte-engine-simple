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
      if error?
        console.error error.stack
      @push null
      next?()

  _insertMetadata: (message, config) =>
    {fromNodeId}        = @metadata
    return unless config.nodeMap?[fromNodeId]?

    {nodeId}            = config.nodeMap[fromNodeId]
    {devices}           = message
    {forwardMetadataTo} = config

    return if _.isEmpty _.intersection devices, forwardMetadataTo
    _.set message, 'metadata.flow.fromNodeId', nodeId

module.exports = EngineOutput
