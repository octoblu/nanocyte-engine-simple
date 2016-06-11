_           = require 'lodash'
debug       = require('debug')('nanocyte-engine-simple:engine-to-nanocyte-stream')
{Transform} = require 'stream'
Bluprint    = require './bluprint'

class EngineToNanocyteStream extends Transform
  constructor: (options, dependencies={}) ->
    super objectMode: true
    {@flowId, @instanceId, @toNodeId, @metadata} = options

    {@datastore} = dependencies
    @datastore ?= new (require './datastore') options, dependencies

  _done: (next, error) =>
    @push null
    next(error) if next?

  _transform: (message, enc, next) =>
    return @_done next, new Error 'missing message' unless message?
    return @_sendNodeConfig {message, next} if @toNodeId == 'engine-output'

    @datastore.hget @flowId, "#{@instanceId}/bluprint/config", (error, bluprintConfig) =>
      return @_done next, error if error?
      return @_moisten({message, bluprintConfig, next}) if bluprintConfig?
      @_sendNodeConfig {message, next}

  _moisten: ({message, bluprintConfig, next}) =>
    {appId, version, configSchema} = bluprintConfig
    bluprint = new Bluprint

    fields = [
      "#{version}/engine-data/config"
      "#{version}/#{@toNodeId}/config"
    ]

    @datastore.hmget appId, fields, (error, [dataConfig, config]) =>
      return @_done next, error if error?
      dataConfig ?= {}
      config ?= {}
      nodeId = dataConfig[@toNodeId]?.nodeId
      nodeId ?= @toNodeId
      config = bluprint.applyConfigToRuntime {
        runtime: config
        configSchema: configSchema
        config: bluprintConfig.config
      }

      @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
        return @_done next, error if error?
        data ?= {}
        @push {message, config, data, @metadata}
        @_done next

  _sendNodeConfig: ({message, next}) =>
    fields = [
      "#{@instanceId}/engine-data/config"
      "#{@instanceId}/#{@toNodeId}/config"
    ]

    @datastore.hmget @flowId, fields, (error, [dataConfig, config]) =>
      return @_done next, error if error?
      dataConfig ?= {}
      config ?= {}
      nodeId = dataConfig[@toNodeId]?.nodeId
      nodeId ?= @toNodeId

      @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
        return @_done next, error if error?
        data ?= {}
        @push {message, config, data, @metadata}
        @_done next

module.exports = EngineToNanocyteStream
