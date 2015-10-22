_ = require 'lodash'
{Transform} = require 'stream'

class EngineToNanocyteStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId} = options

    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (message, enc, next) =>
    @datastore.hget @flowId, "#{@instanceId}/engine-data/config", (error, dataConfig) =>
      @datastore.hget @flowId, "#{@instanceId}/#{@toNodeId}/config", (error, config) =>
        toNodeId = dataConfig[@toNodeId]?.toNodeId
        toNodeId ?= @toNodeId
        @datastore.hget @flowId, "#{@instanceId}/#{toNodeId}/data", (error, data) =>          
          @push message: message, config: config, data: data
          next()
    return


module.exports = EngineToNanocyteStream
