_ = require 'lodash'

class Bluprint

  applyConfigToRuntime: ({runtime, configSchema, config, toNodeId}) =>
    configSchema = configSchema.properties.options if configSchema.properties?.options?
    config = config.options if config.options?

    return @_applyConfigToEngineInput {runtime, configSchema, config} if toNodeId == 'engine-input'
    _.each configSchema.properties, (value, key) =>
      nodeMaps = _.filter value['x-node-map'], id: runtime.id
      _.each nodeMaps, (nodeMap) =>
        _.set runtime, nodeMap.property, _.get(config, key)

    runtime

  _applyConfigToEngineInput: ({runtime, configSchema, config}) =>
    return runtime if _.isEmpty config || _.isEmpty configSchema

    configSchema = configSchema.properties.options if configSchema.properties?.options?
    config = config.options if config.options?

    newRuntime = {}
    _.each configSchema.properties, (property, key) =>
      newDevice = config[key]
      schemaNodeIds = _.map _.filter(property['x-node-map'], property: 'uuid'), ({id}) => nodeId: id
      newRuntime[newDevice] = _.union newRuntime[newDevice], schemaNodeIds

    replacedNodeIds = _.union _.flatten _.values newRuntime
    oldRuntime = _.mapValues runtime, (nodeIds, device) =>
      _.reject nodeIds, (nodeId) => _.find replacedNodeIds, nodeId

    newAndOldDevices = _.union _.keys(newRuntime), _.keys(oldRuntime)
    _.each newAndOldDevices, (device) =>
      newNodeIds = _.compact [].concat(newRuntime[device], oldRuntime[device])
      newRuntime[device] = newNodeIds unless _.isEmpty newNodeIds

    return newRuntime

module.exports = Bluprint
