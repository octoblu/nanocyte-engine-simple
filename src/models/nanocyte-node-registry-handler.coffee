_ = require 'lodash'
class NanocyteNodeRegistryHandler
  constructor: (options={}, dependencies={}) ->
    {@registryUrl} = options
    {@request} = dependencies

  getComponents: (callback) =>
    @getComponentListFromUrl @registryUrl, (error, componentNames) =>
      return callback error if error?      
      callback null, null

  getComponentListFromUrl: (registryUrl, callback) =>
    @request url: @registryUrl, json: true, (error, response, registry) =>
      return callback error if error?
      callback null, @getComponentList registry

  getComponentList: (registry) =>
    nodeDefinitions = _.values registry
    componentNames =
      _.chain(nodeDefinitions)
        .map(@getComponentsForNode)
        .flatten()
        .uniq()
        .value()

    return componentNames

  getComponentsForNode: (node) =>
    components =
      _.chain(node.composedOf)
        .values()
        .pluck('type')
        .uniq()
        .value()

    return components



module.exports = NanocyteNodeRegistryHandler
