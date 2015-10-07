_ = require 'lodash'
class NanocyteNodeRegistryHandler
  constructor: (options={}, dependencies={}) ->
    {@registryUrl} = options
    {@request, @componentClasses} = dependencies

    @request ?= require 'request'
    @componentClasses ?= []

  getComponentMap: (callback) =>
    @getComponentListFromUrl @registryUrl, (error, componentNames) =>
      return callback error if error?

      getKeyForComponent = (map, componentName) =>
        map[componentName] = @loadComponentClass componentName
        return map

      componentMap = _.reduce componentNames, getKeyForComponent, {}

      callback null, componentMap

  getComponentListFromUrl: (registryUrl, callback) =>
    @request url: @registryUrl, json: true, (error, response, registry) =>
      return callback error if error?
      callback null, @getComponentList registry

  getComponentList: (registry) =>
    nodeDefinitions = _.values registry
    componentNames =
      _.chain(nodeDefinitions)
        .map(@getComponentMapForNode)
        .flatten()
        .uniq()
        .value()

    return componentNames

  getComponentMapForNode: (node) =>
    componentNames =
      _.chain(node.composedOf)
        .values()
        .pluck('type')
        .uniq()
        .value()

    return componentNames

  loadComponentClass: (componentName) =>
    return @componentClasses[componentName] if @componentClasses[componentName]?
    console.log 'componentName was', componentName
    try
      return require componentName
    catch
      console.error "Couldn't find a component named #{componentName}"
      return

module.exports = NanocyteNodeRegistryHandler
