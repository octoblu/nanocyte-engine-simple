{Transform} = require 'stream'
Datastore = require './datastore'

class EngineData extends Transform
  constructor: (metadata, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @fromNodeId} = metadata

    {@datastore} = dependencies
    @datastore ?= new Datastore

  _transform: ({message, data, config}, enc, next) =>
    nodeId = config[@fromNodeId]?.nodeId
    @push null

    unless nodeId?
      console.error "engine-data.coffee: Node config not found for '#{@fromNodeId}'"
      return next()

    @datastore.hset @flowId, "#{@instanceId}/#{nodeId}/data", message, next

module.exports = EngineData
