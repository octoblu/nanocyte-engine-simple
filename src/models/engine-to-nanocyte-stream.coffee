_ = require 'lodash'
debug = require('debug')('nanocyte-engine-simple:engine-to-nanocyte-stream')
{Transform} = require 'stream'

class EngineToNanocyteStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId} = options

    {@datastore} = dependencies
    @datastore ?= new (require './datastore') options, dependencies

  _done: (next, error) =>
    @push null
    next(error) if next?

  _transform: (message, enc, next) =>
    return @_done next, new Error 'missing message' unless message?

    @datastore.hget @flowId, "#{@instanceId}/engine-data/config", (error, dataConfig) =>
      return @_done next, error if error?
      dataConfig ?= {}

      @datastore.hget @flowId, "#{@instanceId}/#{@toNodeId}/config", (error, config) =>
        return @_done next, error if error?
        config ?= {}
        nodeId = dataConfig[@toNodeId]?.nodeId
        nodeId ?= @toNodeId

        @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
          return @_done next, error if error?
          data ?= {}
          @push message: message, config: config, data: data
          @_done next

module.exports = EngineToNanocyteStream
