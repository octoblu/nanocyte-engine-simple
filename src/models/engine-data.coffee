{Transform} = require 'stream'
Datastore = require './datastore'
debug = require('debug')('nanocyte-engine-simple:engine-data')

class EngineData extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @fromNodeId} = metadata

    {@datastore} = dependencies
    @datastore ?= new Datastore null, dependencies

  _done: (next, error) =>
    @push null
    next(error) if next?

  _logError: (message, next) =>
    console.error message
    @_done next, new Error message

  _transform: ({message, data, config}, enc, next) =>
    return _logError "engine-data.coffee: config not found for '#{@fromNodeId}'", next unless config?
    nodeId = config[@fromNodeId]?.nodeId
    return _logError "engine-data.coffee: Node config not found for '#{@fromNodeId}'", next unless nodeId?

    debug "setting data for #{nodeId} to", message
    @datastore.hset @flowId, "#{@instanceId}/#{nodeId}/data", message, (error, result) =>
      debug "datastore responded with", error, result
      @_done next, error

module.exports = EngineData
