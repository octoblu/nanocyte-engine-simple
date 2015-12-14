{Transform} = require 'stream'
Datastore = require './datastore'
debug = require('debug')('nanocyte-engine-simple:engine-data')

class EngineData extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @fromNodeId} = metadata

    {@datastore} = dependencies
    @datastore ?= new Datastore null, dependencies

  _transform: ({message, data, config}, enc, next) =>
    unless config?
      console.error "engine-data.coffee: config not found for '#{@fromNodeId}'"
      @push null
      return next()

    nodeId = config[@fromNodeId]?.nodeId
    unless nodeId?
      console.error "engine-data.coffee: Node config not found for '#{@fromNodeId}'"
      @push null
      return next()

    debug "setting data for #{nodeId} to", message
    @datastore.hset @flowId, "#{@instanceId}/#{nodeId}/data", message, (error, result) =>
      debug "datastore responded with", error, result
      @push null
      next error

module.exports = EngineData
