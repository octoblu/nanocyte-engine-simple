{Transform} = require 'stream'
Datastore = require './datastore'

class EngineData extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new Datastore

  _transform: (envelope, enc, next) =>
    {flowId,instanceId,fromNodeId,message,config} = envelope
    toNodeId = config[fromNodeId]?.toNodeId
    @push null

    unless toNodeId?
      console.error "engine-data.coffee: Node config not found for '#{fromNodeId}'"
      return next()

    @datastore.hset flowId, "#{instanceId}/#{toNodeId}/data", message, next

module.exports = EngineData
