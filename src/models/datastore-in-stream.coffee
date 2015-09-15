_ = require 'lodash'

class DatastoreInStream
  constructor: (options, dependencies={}) ->
    {@datastore} = dependencies
    @datastore ?= require '../handlers/datastore-handler'

  onEnvelope: (envelope, callback) =>
    @datastore.get "#{envelope.flowId}/#{envelope.toNodeId}/config", (error, config) =>
      @datastore.get "#{envelope.flowId}/#{envelope.toNodeId}/data", (error, data) =>
        callback null, _.extend {}, envelope, config: config, data: data

module.exports = DatastoreInStream
