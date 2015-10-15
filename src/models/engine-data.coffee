{Writable} = require 'stream'
Datastore = require './datastore'

class EngineData extends Writable
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new Datastore

  _write: (envelope, enc, next) =>
    {flowId,instanceId,fromNodeId,message,config} = envelope
    nodeId = config[fromNodeId]?.nodeId
    next()
    return console.error "engine-data.coffee: Node config not found for '#{fromNodeId}'" unless nodeId?
    @datastore.hset flowId, "#{instanceId}/#{nodeId}/data", message

module.exports = EngineData
