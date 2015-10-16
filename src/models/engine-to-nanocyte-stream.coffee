_ = require 'lodash'
{Transform} = require 'stream'

class EngineToNanocyteStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @nodeId} = options

    {@datastore} = dependencies
    @datastore ?= new (require './datastore')

  _transform: (message, enc, next) =>
    @datastore.hget @flowId, "#{@instanceId}/engine-data/config", (error, dataConfig) =>
      nodeId = dataConfig[@nodeId]?.nodeId
      nodeId ?= @nodeId
      @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/config", (error, config) =>
        @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
          @push message: message, config: config, data: data
          next()
    return


module.exports = EngineToNanocyteStream
