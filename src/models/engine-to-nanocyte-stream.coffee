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
      return @push null if error?
      return @push null unless dataConfig?

      @datastore.hget @flowId, "#{@instanceId}/#{@toNodeId}/config", (error, config) =>
        return @push null if error?

        nodeId = dataConfig[@toNodeId]?.nodeId
        nodeId ?= @toNodeId
        @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
          return @push null if error?

          @push message: message, config: config, data: data
          next()
    return


module.exports = EngineToNanocyteStream
