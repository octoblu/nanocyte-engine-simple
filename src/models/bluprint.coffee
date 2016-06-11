_ = require 'lodash'

class Bluprint

  applyConfigToRuntime: ({runtime, configSchema, config}) =>
    _.each configSchema.properties, (value, key) =>
      nodeMaps = _.filter value['x-node-map'], id: runtime.id
      _.each nodeMaps, (nodeMap) =>
        _.set runtime, nodeMap.property, _.get(config, key)

    runtime

module.exports = Bluprint
