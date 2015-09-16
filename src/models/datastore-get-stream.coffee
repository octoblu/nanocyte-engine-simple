_ = require 'lodash'
{Transform} = require 'stream'

class DatastoreGetStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@datastore} = dependencies
    @datastore ?= require '../handlers/datastore-handler'

  _transform: (envelope, enc, next) =>
    @datastore.get "#{envelope.flowId}/#{envelope.toNodeId}/config", (error, config) =>
      @datastore.get "#{envelope.flowId}/#{envelope.toNodeId}/data", (error, data) =>
        @push _.extend {}, envelope, config: config, data: data
        @push null
        next()

module.exports = DatastoreGetStream
