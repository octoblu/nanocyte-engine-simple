_ = require 'lodash'

class ComponentLoader
  constructor: (options={}, dependencies={}) ->
    {@registry} = options
    {@componentClasses} = dependencies

    @request ?= require 'request'
    @componentClasses ?= []

  getComponentMap: =>
    componentNames = @getComponentList @registry

    getKeyForComponent = (map, componentName) =>
      map[componentName] = @loadComponentClass componentName
      return map

    componentMap = _.reduce componentNames, getKeyForComponent, {}

  getComponentListFromUrl: (registryUrl, callback) =>
    @request url: @registryUrl, json: true, (error, response, registry) =>
      return callback error if error?
      callback null, @getComponentList registry

  getComponentList: (registry) =>
    registry ?= require '../../nanocyte-node-registry.json'
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
    try
      return require componentName
    catch
      console.error "Couldn't find a component named #{componentName}"
      return

module.exports = ComponentLoader
