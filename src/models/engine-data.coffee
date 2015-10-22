{Writable} = require 'stream'
Datastore = require './datastore'

class EngineData extends Writable
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new Datastore

  _write: (envelope, enc, next) =>
    {flowId,instanceId,fromNodeId,message,config} = envelope
    toNodeId = config[fromNodeId]?.toNodeId
    return console.error "engine-data.coffee: Node config not found for '#{fromNodeId}'" unless toNodeId?
    @datastore.hset flowId, "#{instanceId}/#{toNodeId}/data", message, next

module.exports = EngineData
