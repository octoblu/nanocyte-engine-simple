_           = require 'lodash'
debug       = require('debug')('nanocyte-engine-simple:engine-to-nanocyte-stream')
{Transform} = require 'stream'
IotApp      = require './iot-app'

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

    @datastore.hget @flowId, "#{@instanceId}/iot-app/config", (error, iotAppConfig) =>
      return @_done next, error if error?
      return @_moisten({message, iotAppConfig, next}) if iotAppConfig?
      @_sendNodeConfig {message, next}

  _moisten: ({message, iotAppConfig, next}) =>
    {appName, version, configSchema} = iotAppConfig
    iotApp = new IotApp

    @datastore.hget appName, "#{version}/engine-data/config", (error, dataConfig) =>
      return @_done next, error if error?
      dataConfig ?= {}

      @datastore.hget appName, "#{version}/#{@toNodeId}/config", (error, config) =>
        return @_done next, error if error?
        config ?= {}
        nodeId = dataConfig[@toNodeId]?.nodeId
        nodeId ?= @toNodeId

        config = iotApp.applyConfigToRuntime {
          runtime: config
          configSchema: configSchema
          config: iotAppConfig.config
        }

        @datastore.hget @flowId, "#{@instanceId}/#{nodeId}/data", (error, data) =>
          return @_done next, error if error?
          data ?= {}
          @push {message, config, data, @metadata}
          @_done next

  _sendNodeConfig: ({message, next}) =>
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
          @push {message, config, data, @metadata}
          @_done next

module.exports = EngineToNanocyteStream
