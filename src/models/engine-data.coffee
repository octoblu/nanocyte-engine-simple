{Transform} = require 'stream'
Datastore = require './datastore'
debug = require('debug')('nanocyte-engine-simple:engine-data')

class EngineData extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @fromNodeId} = metadata

    {@datastore} = dependencies
    @datastore ?= new Datastore

  _transform: ({message, data, config}, enc, next) =>
    debug "data is currently", data
    nodeId = config[@fromNodeId]?.nodeId
    unless nodeId?
      console.error "engine-data.coffee: Node config not found for '#{@fromNodeId}'"
      return next()

    debug "setting data for #{nodeId} to", message
    @datastore.hset @flowId, "#{@instanceId}/#{nodeId}/data", message, (error, result)=>
      debug "datastore responded with", error, result
      @push null
      next()

module.exports = EngineData
