_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:envelope-stream')
{Transform} = require 'stream'

class EnvelopeStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @nodeId} = options

    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

    debug "constructed EnvelopeStream"

  _transform: (message, enc, next) =>
    debug "EnvelopeStream: I'd add config and data, if I only knew how."
    debug message
    @push metadata: 'hello!', message: message
    next()

module.exports = EnvelopeStream
#
# class DatastoreGetStream extends Transform
#   constructor: (options, dependencies={}) ->
#     super objectMode: true
#
#
#   _transform: (envelope, enc, next) =>
#     debug '_transform', envelope
#
#     @datastore.hget envelope.flowId, "#{envelope.instanceId}/engine-data/config", (error, dataConfig) =>
#       nodeId = dataConfig[envelope.toNodeId]?.nodeId
#       nodeId ?= envelope.toNodeId
#       @datastore.hget envelope.flowId, "#{envelope.instanceId}/#{envelope.toNodeId}/config", (error, config) =>
#         @datastore.hget envelope.flowId, "#{envelope.instanceId}/#{nodeId}/data", (error, data) =>
#           @push _.extend {}, envelope, config: config, data: data
#           next()
