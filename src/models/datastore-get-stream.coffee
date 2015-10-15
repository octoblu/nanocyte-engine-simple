_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:datastore-get-stream')
{Transform} = require 'stream'

class DatastoreGetStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (envelope, enc, next) =>
    debug '_transform', envelope

    @datastore.hget envelope.flowId, "#{envelope.instanceId}/engine-data/config", (error, dataConfig) =>
      nodeId = dataConfig[envelope.toNodeId]?.nodeId
      nodeId ?= envelope.toNodeId
      @datastore.hget envelope.flowId, "#{envelope.instanceId}/#{envelope.toNodeId}/config", (error, config) =>
        @datastore.hget envelope.flowId, "#{envelope.instanceId}/#{nodeId}/data", (error, data) =>
          @push _.extend {}, envelope, config: config, data: data
          next()

module.exports = DatastoreGetStream
