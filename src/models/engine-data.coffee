{Writable} = require 'stream'

class EngineData extends Writable
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _write: (envelope, enc, next) =>
    {flowId,instanceId,fromNodeId,message,config} = envelope
    nodeId = config[fromNodeId]?.nodeId
    return console.error "engine-data.coffee: Node config not found for '#{fromNodeId}'" unless nodeId?
    @datastore.set "#{flowId}/#{instanceId}/#{nodeId}/data", message, next

module.exports = EngineData
