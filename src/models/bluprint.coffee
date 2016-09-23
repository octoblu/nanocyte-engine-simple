_ = require 'lodash'

class Bluprint

  applyConfigToRuntime: ({runtime, configSchema, config, toNodeId}) =>
    return @_applyConfigToEngineInput {runtime, configSchema, config} if toNodeId == 'engine-input'
    _.each configSchema.properties, (value, key) =>
      nodeMaps = _.filter value['x-node-map'], id: runtime.id
      _.each nodeMaps, (nodeMap) =>
        _.set runtime, nodeMap.property, _.get(config, key)

    runtime

  _applyConfigToEngineInput: ({runtime, configSchema, config}) =>
    return runtime if _.isEmpty config || _.isEmpty configSchema

    newRuntime = _.mapKeys runtime, (runtimeNodeList, device) =>
      runtimeNodeIds = _.map runtimeNodeList, 'nodeId'
      newDevice = _.first _.flatten _.map configSchema.properties, (property, key) =>
        return null unless property?
        schemaNodeIds = _.map _.filter(property['x-node-map'], property: 'uuid'), 'id'
        return config[key] if _.isEmpty _.difference runtimeNodeIds, schemaNodeIds

      return newDevice || device

    return newRuntime

module.exports = Bluprint
