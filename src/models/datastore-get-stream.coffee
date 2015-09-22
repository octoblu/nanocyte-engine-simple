_ = require 'lodash'
{Transform} = require 'stream'

class DatastoreGetStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (envelope, enc, next) =>
    @datastore.get "#{envelope.flowId}/#{envelope.instanceId}/engine-data/config", (error, dataConfig) =>
      nodeId = dataConfig[envelope.toNodeId]?.nodeId
      nodeId ?= envelope.toNodeId
      @datastore.get "#{envelope.flowId}/#{envelope.instanceId}/#{envelope.toNodeId}/config", (error, config) =>
        @datastore.get "#{envelope.flowId}/#{envelope.instanceId}/#{nodeId}/data", (error, data) =>
          @push _.extend {}, envelope, config: config, data: data
          @push null
          next()

module.exports = DatastoreGetStream
